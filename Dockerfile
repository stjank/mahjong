FROM eclipse-temurin:17-jdk-jammy

RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip wget \
    && rm -rf /var/lib/apt/lists/*

# ── Android SDK ───────────────────────────────────────────────────────────────
ENV ANDROID_SDK_ROOT=/opt/android-sdk
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget -q "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
        -O /tmp/cmdtools.zip && \
    unzip -q /tmp/cmdtools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools \
       ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm /tmp/cmdtools.zip

ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

RUN yes | sdkmanager --licenses && \
    sdkmanager \
        "platform-tools" \
        "platforms;android-35" \
        "build-tools;35.0.0" \
        "ndk;28.2.13676358"

# ── Flutter ───────────────────────────────────────────────────────────────────
ENV FLUTTER_HOME=/opt/flutter
RUN wget -q "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.1-stable.tar.xz" \
        -O /tmp/flutter.tar.xz && \
    tar -xf /tmp/flutter.tar.xz -C /opt && \
    rm /tmp/flutter.tar.xz

ENV PATH="${FLUTTER_HOME}/bin:${PATH}"
RUN git config --global --add safe.directory /opt/flutter && \
    flutter config --no-analytics && flutter precache --android

# ── Dependencies (cached layer) ───────────────────────────────────────────────
WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

# ── Project source ─────────────────────────────────────────────────────────────
COPY . .
RUN flutter build apk --release

CMD ["echo", "Build complete. APK at /app/build/app/outputs/flutter-apk/app-release.apk"]
