/*
 * Copyright (C) 2018 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package androidx.test.ext.truth.os;

import static com.google.common.truth.Fact.simpleFact;

import android.os.Bundle;
import android.os.Parcelable;
import androidx.annotation.NonNull;
import com.google.common.truth.BooleanSubject;
import com.google.common.truth.DoubleSubject;
import com.google.common.truth.FailureMetadata;
import com.google.common.truth.IntegerSubject;
import com.google.common.truth.IterableSubject;
import com.google.common.truth.LongSubject;
import com.google.common.truth.ObjectArraySubject;
import com.google.common.truth.PrimitiveByteArraySubject;
import com.google.common.truth.StringSubject;
import com.google.common.truth.Subject;
import com.google.common.truth.Truth;

// LINT.IfChange
// TODO(b/308978831) once minSdkVersion >= 21, unify most methods with PersistableBundleSubject
// through a (library-internal) BaseBundleSubject superclass.
/**
 * Subject for making assertions about {@link Bundle}s.
 *
 * <p>To assert about {@link android.os.PersistableBundle}s, use {@link PersistableBundleSubject}.
 */
public final class BundleSubject extends Subject {

  public static BundleSubject assertThat(Bundle bundle) {
    return Truth.assertAbout(bundles()).that(bundle);
  }

  public static Subject.Factory<BundleSubject, Bundle> bundles() {
    return BundleSubject::new;
  }

  private final Bundle actual;

  BundleSubject(FailureMetadata failureMetadata, Bundle subject) {
    super(failureMetadata, subject);
    this.actual = subject;
  }

  public void hasSize(int size) {
    check("size()").that(actual.size()).isEqualTo(size);
  }

  public void isEmpty() {
    if (!actual.isEmpty()) {
      failWithActual(simpleFact("expected to be empty"));
    }
  }

  public void isNotEmpty() {
    if (actual.isEmpty()) {
      failWithActual(simpleFact("expected to be non-empty"));
    }
  }

  public StringSubject string(String key) {
    return check("getString(%s)", key).that(actual.getString(key));
  }

  public IntegerSubject integer(String key) {
    return check("getInt(%s)", key).that(actual.getInt(key));
  }

  public LongSubject longInt(String key) {
    return check("getLong(%s)", key).that(actual.getLong(key));
  }

  @NonNull
  public DoubleSubject doubleFloat(@NonNull String key) {
    return check("getDouble(%s)", key).that(actual.getDouble(key));
  }

  public BooleanSubject bool(String key) {
    return check("getBoolean(%s)", key).that(actual.getBoolean(key));
  }

  public PrimitiveByteArraySubject byteArray(String key) {
    return check("getByteArray(%s)", key).that(actual.getByteArray(key));
  }

  public <T extends Parcelable> ParcelableSubject<T> parcelable(String key) {
    return check("getParcelable(%s)", key)
        .about(ParcelableSubject.<T>parcelables())
        .that(actual.<T>getParcelable(key));
  }

  public <T extends Parcelable, SubjectT extends Subject> SubjectT parcelableAsType(
      String key, Subject.Factory<SubjectT, T> subjectFactory) {
    return check("getParcelable(%s)", key).about(subjectFactory).that(actual.<T>getParcelable(key));
  }

  @NonNull
  public ObjectArraySubject<String> stringArray(@NonNull String key) {
    return check("getStringArray(%s)", key).that(actual.getStringArray(key));
  }

  public IterableSubject stringArrayList(String key) {
    return check("getStringArrayList(%s)", key).that(actual.getStringArrayList(key));
  }

  public IterableSubject parcelableArrayList(String key) {
    return check("getParcelableArrayList(%s)", key).that(actual.getParcelableArrayList(key));
  }

  /** Returns a truth subject for the value associated with the given key. */
  public Subject serializable(String key) {
    return check("getSerializable(%s)", key).that(actual.getSerializable(key));
  }

  public void containsKey(String key) {
    if (!actual.containsKey(key)) {
      failWithActual(simpleFact("expected to contain key " + key));
    }
  }

  public void doesNotContainKey(String key) {
    if (actual.containsKey(key)) {
      failWithActual(simpleFact("expected to not contain key " + key));
    }
  }
}
// LINT.ThenChange(PersistableBundleSubject.java)
