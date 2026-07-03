// -------------------------------------------------------------------------------------------
// File version 1002
// -------------------------------------------------------------------------------------------
// Calculate current job statistics
FUNCTION CalcStatsJob
	// -------------------------------------------------------------------------------------------
	// Calculate total time, remember total time in milliseconds for accuaracy but convert to seconds for local calculations
	exLink.JobTotalTime := exLink.JobTotalTime + DiffLastCall;
	JobTotalTime := LREAL_TO_UDINT(exLink.JobTotalTime/1000);

	exLink.JobStatistics.TotalTime.Hours := JobTotalTime/3600;
	exLink.JobStatistics.TotalTime.Minutes := UDINT_TO_USINT((JobTotalTime - exLink.JobStatistics.TotalTime.Hours*3600)/60);
	exLink.JobStatistics.TotalTime.Seconds := UDINT_TO_USINT(JobTotalTime - exLink.JobStatistics.TotalTime.Hours*3600 - exLink.JobStatistics.TotalTime.Minutes*60);
	
	// Calculate scheduled downtime
	IF Downtime = exASSETINT_SCHEDULED_DOWNTIME THEN
		exLink.JobDowntimeScheduled := exLink.JobDowntimeScheduled + DiffLastCall;
		exLink.JobStatistics.ScheduledDowntime.Hours := exLink.JobDowntimeScheduled/3600000;
		exLink.JobStatistics.ScheduledDowntime.Minutes := UDINT_TO_USINT((exLink.JobDowntimeScheduled - exLink.JobStatistics.ScheduledDowntime.Hours*3600000)/60000);
		exLink.JobStatistics.ScheduledDowntime.Seconds := UDINT_TO_USINT((exLink.JobDowntimeScheduled - exLink.JobStatistics.ScheduledDowntime.Hours*3600000 - exLink.JobStatistics.ScheduledDowntime.Minutes*60000)/1000);
	END_IF

	// Calculate unscheduled downtime
	IF Downtime = exASSETINT_UNSCHEDULED_DOWNTIME THEN
		exLink.JobDowntimeUnscheduled := exLink.JobDowntimeUnscheduled + DiffLastCall;
		exLink.JobStatistics.UnscheduledDowntime.Hours := exLink.JobDowntimeUnscheduled/3600000;
		exLink.JobStatistics.UnscheduledDowntime.Minutes := UDINT_TO_USINT((exLink.JobDowntimeUnscheduled - exLink.JobStatistics.UnscheduledDowntime.Hours*3600000)/60000);
		exLink.JobStatistics.UnscheduledDowntime.Seconds := UDINT_TO_USINT((exLink.JobDowntimeUnscheduled - exLink.JobStatistics.UnscheduledDowntime.Hours*3600000 - exLink.JobStatistics.UnscheduledDowntime.Minutes*60000)/1000);
	END_IF
	
	// Calculate uptime
	IF Downtime = exASSETINT_NO_DOWNTIME THEN
		Uptime := JobTotalTime - exLink.JobDowntimeScheduled/1000 - exLink.JobDowntimeUnscheduled/1000;
		exLink.JobStatistics.Uptime.Hours := Uptime/3600;
		exLink.JobStatistics.Uptime.Minutes := UDINT_TO_USINT((Uptime - exLink.JobStatistics.Uptime.Hours*3600)/60);
		exLink.JobStatistics.Uptime.Seconds := UDINT_TO_USINT(Uptime - exLink.JobStatistics.Uptime.Hours*3600 - exLink.JobStatistics.Uptime.Minutes*60);
	END_IF
	
	// -------------------------------------------------------------------------------------------
	// Calculate counters
	IF exLink.JobStatistics.TotalPieces > exLink.JobStatistics.RejectPieces THEN
		exLink.JobStatistics.GoodPieces := exLink.JobStatistics.TotalPieces - exLink.JobStatistics.RejectPieces;
	ELSE
		exLink.JobStatistics.GoodPieces := 0;
		exLink.JobStatistics.RejectPieces := exLink.JobStatistics.TotalPieces;		
	END_IF	
	IF exLink.JobStatistics.TotalPieces > 0 THEN
		exLink.JobStatistics.BadPieceRate := UDINT_TO_REAL(exLink.JobStatistics.RejectPieces)/UDINT_TO_REAL(exLink.JobStatistics.TotalPieces);
	END_IF

	// -------------------------------------------------------------------------------------------
	// Additional times and rates
	IF Parameter.NominalProductionRate > 0.0 THEN
		NominalProductionTime := REAL_TO_UDINT(UDINT_TO_REAL(exLink.JobStatistics.TotalPieces)*(3600/Parameter.NominalProductionRate));
	ELSE
		NominalProductionTime := 0;
	END_IF
	exLink.JobStatistics.NominalProductionTime.Hours := NominalProductionTime/3600;
	exLink.JobStatistics.NominalProductionTime.Minutes := UDINT_TO_USINT((NominalProductionTime - exLink.JobStatistics.NominalProductionTime.Hours*3600)/60);
	exLink.JobStatistics.NominalProductionTime.Seconds := UDINT_TO_USINT(NominalProductionTime - exLink.JobStatistics.NominalProductionTime.Hours*3600 - exLink.JobStatistics.NominalProductionTime.Minutes*60);

	IF Parameter.NominalProductionRate > 0.0 THEN
		GoodProductionTime := REAL_TO_UDINT(UDINT_TO_REAL(exLink.JobStatistics.GoodPieces)*(3600/Parameter.NominalProductionRate));
	ELSE
		GoodProductionTime := 0;
	END_IF
	exLink.JobStatistics.GoodProductionTime.Hours := GoodProductionTime/3600;
	exLink.JobStatistics.GoodProductionTime.Minutes := UDINT_TO_USINT((GoodProductionTime - exLink.JobStatistics.GoodProductionTime.Hours*3600)/60);
	exLink.JobStatistics.GoodProductionTime.Seconds := UDINT_TO_USINT(GoodProductionTime - exLink.JobStatistics.GoodProductionTime.Hours*3600 - exLink.JobStatistics.GoodProductionTime.Minutes*60);
	
	IF exLink.JobDowntimeScheduled > 0 AND JobTotalTime > 0 THEN
		exLink.JobStatistics.ScheduledDowntimeRate := UDINT_TO_REAL(exLink.JobDowntimeScheduled)/UDINT_TO_REAL(JobTotalTime)/1000;
	END_IF
	IF exLink.JobDowntimeUnscheduled > 0 AND JobTotalTime > 0 THEN
		exLink.JobStatistics.UnscheduledDowntimeRate := UDINT_TO_REAL(exLink.JobDowntimeUnscheduled)/UDINT_TO_REAL(JobTotalTime)/1000;
	END_IF
	IF Uptime > 0 THEN
		exLink.JobStatistics.NominalProductionTimeRate := UDINT_TO_REAL(NominalProductionTime)/UDINT_TO_REAL(Uptime);
	END_IF
	IF JobTotalTime > 0 THEN
		exLink.JobStatistics.CurrentProductionRate := UDINT_TO_REAL(exLink.JobStatistics.TotalPieces)/UDINT_TO_REAL(JobTotalTime)*3600;
	END_IF
	
	brsmemcpy(ADR(JobStatistics), ADR(exLink.JobStatistics), SIZEOF(exLink.JobStatistics));
	CalcStatsJob := TRUE;
END_FUNCTION

// -------------------------------------------------------------------------------------------
// Calculate current shift statistics
FUNCTION CalcStatsShift
	// -------------------------------------------------------------------------------------------
	// Calculate total time, remember total time in milliseconds for accuaracy but convert to seconds for local calculations
	exLink.ShiftTotalTime := exLink.ShiftTotalTime + DiffLastCall;
	ShiftTotalTime := LREAL_TO_UDINT(exLink.ShiftTotalTime/1000);
	
	exLink.ShiftStatistics.TotalTime.Hours := ShiftTotalTime/3600;
	exLink.ShiftStatistics.TotalTime.Minutes := UDINT_TO_USINT((ShiftTotalTime - exLink.ShiftStatistics.TotalTime.Hours*3600)/60);
	exLink.ShiftStatistics.TotalTime.Seconds := UDINT_TO_USINT(ShiftTotalTime - exLink.ShiftStatistics.TotalTime.Hours*3600 - exLink.ShiftStatistics.TotalTime.Minutes*60);

	// Calculate scheduled downtime
	IF Downtime = exASSETINT_SCHEDULED_DOWNTIME THEN
		exLink.ShiftDowntimeScheduled := exLink.ShiftDowntimeScheduled + DiffLastCall;
		exLink.ShiftStatistics.ScheduledDowntime.Hours := exLink.ShiftDowntimeScheduled/3600000;
		exLink.ShiftStatistics.ScheduledDowntime.Minutes := UDINT_TO_USINT((exLink.ShiftDowntimeScheduled - exLink.ShiftStatistics.ScheduledDowntime.Hours*3600000)/60000);
		exLink.ShiftStatistics.ScheduledDowntime.Seconds := UDINT_TO_USINT((exLink.ShiftDowntimeScheduled - exLink.ShiftStatistics.ScheduledDowntime.Hours*3600000 - exLink.ShiftStatistics.ScheduledDowntime.Minutes*60000)/1000);
	END_IF

	// Calculate scheduled downtime
	IF Downtime = exASSETINT_UNSCHEDULED_DOWNTIME THEN
		exLink.ShiftDowntimeUnscheduled := exLink.ShiftDowntimeUnscheduled + DiffLastCall;
		exLink.ShiftStatistics.UnscheduledDowntime.Hours := exLink.ShiftDowntimeUnscheduled/3600000;
		exLink.ShiftStatistics.UnscheduledDowntime.Minutes := UDINT_TO_USINT((exLink.ShiftDowntimeUnscheduled - exLink.ShiftStatistics.UnscheduledDowntime.Hours*3600000)/60000);
		exLink.ShiftStatistics.UnscheduledDowntime.Seconds := UDINT_TO_USINT((exLink.ShiftDowntimeUnscheduled - exLink.ShiftStatistics.UnscheduledDowntime.Hours*3600000 - exLink.ShiftStatistics.UnscheduledDowntime.Minutes*60000)/1000);
	END_IF
	
	// Calculate uptime
	IF Downtime = exASSETINT_NO_DOWNTIME THEN
		Uptime := ShiftTotalTime - exLink.ShiftDowntimeScheduled/1000 - exLink.ShiftDowntimeUnscheduled/1000;
		exLink.ShiftStatistics.Uptime.Hours := Uptime/3600;
		exLink.ShiftStatistics.Uptime.Minutes := UDINT_TO_USINT((Uptime - exLink.ShiftStatistics.Uptime.Hours*3600)/60);
		exLink.ShiftStatistics.Uptime.Seconds := UDINT_TO_USINT(Uptime - exLink.ShiftStatistics.Uptime.Hours*3600 - exLink.ShiftStatistics.Uptime.Minutes*60);
	END_IF
	
	// -------------------------------------------------------------------------------------------
	// Calculate counters
	exLink.ShiftStatistics.TargetPieces := LREAL_TO_UDINT(UDINT_TO_REAL(ShiftTotalTime)/3600*Parameter.NominalProductionRate);
	IF exLink.ShiftStatistics.TotalPieces > exLink.ShiftStatistics.RejectPieces THEN
		exLink.ShiftStatistics.GoodPieces := exLink.ShiftStatistics.TotalPieces - exLink.ShiftStatistics.RejectPieces;
	ELSE
		exLink.ShiftStatistics.GoodPieces := 0;
		exLink.ShiftStatistics.RejectPieces := exLink.ShiftStatistics.TotalPieces;		
	END_IF	
	IF exLink.ShiftStatistics.TotalPieces > 0 THEN
		exLink.ShiftStatistics.BadPieceRate := UDINT_TO_REAL(exLink.ShiftStatistics.RejectPieces)/UDINT_TO_REAL(exLink.ShiftStatistics.TotalPieces);
	END_IF

	// -------------------------------------------------------------------------------------------
	// Additional times and rates
	IF Parameter.NominalProductionRate > 0.0 THEN
		NominalProductionTime := REAL_TO_UDINT(UDINT_TO_REAL(exLink.ShiftStatistics.TotalPieces)*(3600/Parameter.NominalProductionRate));
	ELSE
		NominalProductionTime := 0;
	END_IF
	exLink.ShiftStatistics.NominalProductionTime.Hours := NominalProductionTime/3600;
	exLink.ShiftStatistics.NominalProductionTime.Minutes := UDINT_TO_USINT((NominalProductionTime - exLink.ShiftStatistics.NominalProductionTime.Hours*3600)/60);
	exLink.ShiftStatistics.NominalProductionTime.Seconds := UDINT_TO_USINT(NominalProductionTime - exLink.ShiftStatistics.NominalProductionTime.Hours*3600 - exLink.ShiftStatistics.NominalProductionTime.Minutes*60);

	IF Parameter.NominalProductionRate > 0.0 THEN
		GoodProductionTime := REAL_TO_UDINT(UDINT_TO_REAL(exLink.ShiftStatistics.GoodPieces)*(3600/Parameter.NominalProductionRate));
	ELSE
		GoodProductionTime := 0;
	END_IF
	exLink.ShiftStatistics.GoodProductionTime.Hours := GoodProductionTime/3600;
	exLink.ShiftStatistics.GoodProductionTime.Minutes := UDINT_TO_USINT((GoodProductionTime - exLink.ShiftStatistics.GoodProductionTime.Hours*3600)/60);
	exLink.ShiftStatistics.GoodProductionTime.Seconds := UDINT_TO_USINT(GoodProductionTime - exLink.ShiftStatistics.GoodProductionTime.Hours*3600 - exLink.ShiftStatistics.GoodProductionTime.Minutes*60);
	
	IF exLink.ShiftDowntimeScheduled > 0 AND ShiftTotalTime > 0 THEN
		exLink.ShiftStatistics.ScheduledDowntimeRate := UDINT_TO_REAL(exLink.ShiftDowntimeScheduled)/UDINT_TO_REAL(ShiftTotalTime)/1000;
	END_IF
	IF exLink.ShiftDowntimeUnscheduled > 0 AND ShiftTotalTime > 0 THEN
		exLink.ShiftStatistics.UnscheduledDowntimeRate := UDINT_TO_REAL(exLink.ShiftDowntimeUnscheduled)/UDINT_TO_REAL(ShiftTotalTime)/1000;
	END_IF
	IF Uptime > 0 THEN
		exLink.ShiftStatistics.NominalProductionTimeRate := UDINT_TO_REAL(NominalProductionTime)/UDINT_TO_REAL(Uptime);
	END_IF
	IF ShiftTotalTime > 0 THEN
		exLink.ShiftStatistics.CurrentProductionRate := UDINT_TO_REAL(exLink.ShiftStatistics.TotalPieces)/UDINT_TO_REAL(ShiftTotalTime)*3600;
	END_IF
	
	brsmemcpy(ADR(ShiftStatistics), ADR(exLink.ShiftStatistics), SIZEOF(exLink.ShiftStatistics));
	CalcStatsShift := TRUE;
END_FUNCTION