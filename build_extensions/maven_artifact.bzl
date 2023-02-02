"""Skylark rule to create a maven repository from a single artifact."""

load("//build_extensions:copy_file.bzl", "copy_file")
load("//build_extensions:maven_info.bzl", "MavenFiles", "MavenInfo")

_pom_tmpl = "\n".join([
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<project xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd"',
    '    xmlns="http://maven.apache.org/POM/4.0.0"',
    '    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">',
    "  <modelVersion>4.0.0</modelVersion>",
    "  <groupId>{group_id}</groupId>",
    "  <artifactId>{artifact_id}</artifactId>",
    "  <version>{version}</version>",
    "  <packaging>{packaging}</packaging>",
    "  <name>AndroidX Test Library</name>",
    "  <description>The AndroidX Test Library provides an extensive framework for testing Android apps</description>",
    "  <url>https://developer.android.com/testing</url>",
    "  <inceptionYear>2015</inceptionYear>",
    "  <licenses>",
    "    <license>",
    "      <name>The Apache Software License, Version 2.0</name>",
    "      <url>http://www.apache.org/licenses/LICENSE-2.0.txt</url>",
    "      <distribution>repo</distribution>",
    "    </license>",
    "  </licenses>",
    "  <developers>",
    "    <developer>",
    "      <name>The Android Open Source Project</name>",
    "    </developer>",
    "  </developers>",
    "  <dependencies>",
    "{dependencies}",
    "  </dependencies>",
    "</project>",
    "",
])

_dependency_tmpl = "\n".join([
    "    <dependency>",
    "      <groupId>{group_id}</groupId>",
    "      <artifactId>{artifact_id}</artifactId>",
    "      <version>{version}</version>",
    "      <scope>compile</scope>",
    "    </dependency>",
])

_metadata_tmpl = "\n".join([
    '<?xml version="1.0" encoding="UTF-8"?>',
    "<metadata>",
    "  <groupId>{group_id}</groupId>",
    "  <artifactId>{artifact_id}</artifactId>",
    "  <version>{version}</version>",
    "  <versioning>",
    "    <release>{version}</release>",
    "    <versions>",
    "      <version>{version}</version>",
    "    </versions>",
    "  <lastUpdated>{last_updated}</lastUpdated>",
    "  </versioning>",
    "</metadata>",
    "",
])

def _packaging_type(f):
    """Returns the packaging type used by the file f."""
    if f.basename.endswith(".aar"):
        return "aar"
    elif f.basename.endswith(".apk"):
        return "apk"
    elif f.basename.endswith(".jar"):
        return "jar"
    fail("Artifact has unknown packaging type: %s" % f.short_path)

def _create_pom_string(ctx, group_id, artifact_id, version, packaging_type, maven_dependencies):
    """Returns the contents of the pom file as a string."""
    dependencies = []
    for dep in maven_dependencies:
        dep_group_id, dep_artifact_id, dep_version = _parse_artifact_versioning(dep)
        dependencies.append(_dependency_tmpl.format(
            group_id = dep_group_id,
            artifact_id = dep_artifact_id,
            version = dep_version,
        ))

    return _pom_tmpl.format(
        group_id = group_id,
        artifact_id = artifact_id,
        version = version,
        packaging = packaging_type,
        dependencies = "\n".join(dependencies),
    )

def _create_metadata_string(ctx, group_id, artifact_id, version):
    """Returns the string contents of maven-metadata.xml for the group."""
    return _metadata_tmpl.format(
        group_id = group_id,
        artifact_id = artifact_id,
        version = version,
        last_updated = ctx.attr.last_updated,
    )

def _parse_artifact_versioning(artifact_coordinates):
    """Parse out artifact_id, version and group info from a full coordinate string"""
    if artifact_coordinates.count(":") != 2:
        fail("artifact_deps values must be of form: groupId:artifactId:version. Found %s" % artifact_coordinates)

    return artifact_coordinates.split(":")

def _rename_artifact(ctx, tpl_string, src_file, packaging_type, artifact_id, version):
    """Rename the artifact to match maven naming conventions."""
    artifact = ctx.actions.declare_file(tpl_string % (artifact_id, version, packaging_type))
    ctx.actions.run_shell(
        inputs = [src_file],
        outputs = [artifact],
        command = "cp %s %s" % (src_file.path, artifact.path),
    )
    return artifact

def _validate_deps(artifact_id, maven_deps):
    for dep in maven_deps:
        if "com.google.guava:guava" in dep and artifact_id != "truth":
            fail("Guava is not an allowed dependency")
        if "com.google.dagger" in dep:
            fail("com.google.dagger should be a shaded dependency. Depend on //opensource/dagger instead of @maven//:com_google_dagger_dagger")

def _maven_artifact_impl(ctx):
    """Generates maven repository for a single artifact."""

    group_id, artifact_id, version = _parse_artifact_versioning(ctx.attr.target[MavenInfo].artifact)
    pom = ctx.actions.declare_file(
        "%s-%s.pom" % (artifact_id, version),
    )

    maven_deps = sorted(ctx.attr.target[MavenInfo].transitive_maven_direct_deps.to_list())
    _validate_deps(artifact_id, maven_deps)

    packaging_type = _packaging_type(ctx.attr.target[MavenFiles].runtime)
    pom_content = _create_pom_string(ctx, group_id, artifact_id, version, packaging_type, maven_deps)
    ctx.actions.write(output = pom, content = pom_content)

    #copy_file(ctx, pom, ctx.outputs.pom)

    metadata = ctx.actions.declare_file("maven-metadata.xml")
    ctx.actions.write(output = metadata, content = _create_metadata_string(ctx, group_id, artifact_id, version))

    # Rename binary artifact to artifact_id-version.packaging_type
    artifact = _rename_artifact(ctx, "%s-%s.%s", ctx.attr.target[MavenFiles].runtime, packaging_type, artifact_id, version)

    # Rename sources jar artifact to artifact_id-version-sources.jar
    source = _rename_artifact(ctx, "%s-%s-sources.%s", ctx.attr.target[MavenFiles].src_jar, "jar", artifact_id, version)

    arguments = [
        "--group_path=%s" % group_id.replace(".", "/"),
        "--artifact_id=%s" % artifact_id,
        "--version=%s" % version,
        "--artifact=%s" % artifact.path,
        "--source=%s" % source.path,
        "--pom=%s" % pom.path,
        "--metadata=%s" % metadata.path,
        "--output=%s" % ctx.outputs.m2repository.path,
    ]

    inputs = [pom, metadata, artifact, source]

    ctx.actions.run(
        inputs = inputs,
        outputs = [ctx.outputs.m2repository],
        arguments = arguments,
        executable = ctx.executable._maven_artifact_sh,
        progress_message = (
            "Packaging repository: %s" % ctx.outputs.m2repository.short_path
        ),
    )

maven_artifact = rule(
    implementation = _maven_artifact_impl,
    attrs = {
        "target": attr.label(
            doc = "The target to be published to maven. Must be a axt_android_aar or axt_android_apk",
            mandatory = True,
            providers = [MavenInfo, MavenFiles],
        ),
        # TODO: derive this?
        "last_updated": attr.string(mandatory = True),
        "_maven_artifact_sh": attr.label(
            default = Label("//build_extensions:maven_artifact_sh"),
            executable = True,
            allow_files = True,
            cfg = "host",
        ),
    },
    outputs = {
        "m2repository": "%{name}.zip",
        #"pom": "%{name}.pom",
    },
)
