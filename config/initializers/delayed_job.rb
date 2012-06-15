Delayed::Worker.backend = :active_record
Delayed::Job.table_name = "vivi_delayed_jobs"