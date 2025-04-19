# Keep TensorFlow Lite GPU delegate classes
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.nnapi.** { *; }
-keep class org.tensorflow.lite.support.** { *; }

# Optional: Log more if debugging
-dontwarn org.tensorflow.**
