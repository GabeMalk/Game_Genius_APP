# Mantém a classe interna do WorkManager que o R8 removeria por engano
-keep class androidx.work.impl.WorkDatabase_Impl { *; }

# Mantém os construtores de qualquer Worker (usados via reflection)
-keep class * extends androidx.work.ListenableWorker {
    <init>(android.content.Context, androidx.work.WorkerParameters);
}