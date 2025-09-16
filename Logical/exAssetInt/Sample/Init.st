PROGRAM _INIT
	gLocked;					// VC helper
	
	// --------------------------------------------------------------------------------------------------------------------------
	// Shift configuration
	gShift[0].Name := 'Morning';
	gShift[0].Start.Hour := 8;
	gShift[0].Start.Minutes := 0;
	gShift[0].End.Hour := 14;
	gShift[0].End.Minutes := 0;
	gShift[0].ScheduledDowntime[0].Reason := 'Breakfast';
	gShift[0].ScheduledDowntime[0].Start.Hour := 9;
	gShift[0].ScheduledDowntime[0].End.Hour := 9;
	gShift[0].ScheduledDowntime[0].End.Minutes := 15;

	gShift[1].Name := 'Afternoon';
	gShift[1].Start.Hour := 14;
	gShift[1].Start.Minutes := 0;
	gShift[1].End.Hour := 22;
	gShift[1].End.Minutes := 0;

	gShift[2].Name := 'Night';
	gShift[2].Start.Hour := 22;
	gShift[2].Start.Minutes := 0;
	gShift[2].End.Hour := 8;
	gShift[2].End.Minutes := 0;
	
	// --------------------------------------------------------------------------------------------------------------------------
	// Export configuration
	exAssetIntConfig.Export.DecimalMark := ',';
	exAssetIntConfig.Export.ColumnSeparator := ';';

	exAssetIntConfig.Export.ShiftStatistics := TRUE;
	exAssetIntConfig.Export.ShiftStatisticsFileNamePattern := 'ShiftStatistics_%Y_%m_%d_%H_%M.csv';
	
	exAssetIntConfig.Export.JobStatistics := TRUE;
	exAssetIntConfig.Export.JobStatisticsFileNamePattern := 'JobStatistics_%Y_%m_%d_%H_%M.csv';

	exAssetIntConfig.Export.Timeline := TRUE;
	exAssetIntConfig.Export.TimelineFileNamePattern := 'Timeline_%Y_%m_%d_%H_%M.csv';

END_PROGRAM