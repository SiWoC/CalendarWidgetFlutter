# WorkManager + Room (WorkDatabase_Impl is generated; R8 strips it without these rules).
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
-keep class androidx.work.impl.** { *; }
-keepclassmembers class androidx.work.impl.WorkDatabase_Impl {
    <init>();
}
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-keepclassmembers class * extends androidx.room.RoomDatabase {
    abstract ** *;
}

# App periodic refresh worker.
-keep class nl.siwoc.calendarwidget.CalendarRefreshCoroutineWorker { *; }
