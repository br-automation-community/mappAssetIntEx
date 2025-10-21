(*File Version 1008*)
(*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*)
(*Internal type*)

TYPE
	exCoreInternalDataType : 	STRUCT 
		RecordIndexUsed : ARRAY[0..CORE_EVENT_NUM_MAX]OF BOOL; (*Next record ID*)
		RecordIndex : UINT; (*Next record ID*)
		RecordData : exCoreInternalRecordType;
		State : exAssetIntStateEnum;
		StateError : exAssetIntStateEnum := exASSETINT_STATE_NONE;
		InitAfterBoot : BOOL;
		TimeLastCallShift : TIME;
		DiffLastCallShift : UDINT;
		TimeLastCallProduction : TIME;
		DiffLastCallProduction : UDINT;
		JobPieceCounterOld : UDINT;
		JobRejectCounterOld : UDINT;
		ShiftPieceCounterOld : UDINT;
		ShiftRejectCounterOld : UDINT;
		ShiftId : SINT;
		ShiftName : STRING[20];
		TmpStr1 : STRING[500];
		TmpStr2 : STRING[50];
		Downtime : exAssetIntDowntimeEnum;
		DowntimeReason : STRING[50];
		ProductionTotalTime : UDINT;
		CurrentTime : DTGetTime;
		PowerOffTime : DATE_AND_TIME;
		TimeOfDay : TIME_OF_DAY;
		ShiftTotalTimeStart : UDINT;
		StatsRefresh : TON_10ms;
		BackupTimer : TON_10ms;
		DirCreate_0 : DirCreate;
		CreateMemory : CreateMemory;
		ReadEventData : ReadEventData;
		WriteEventData : WriteEventData;
		ReadLinkData : ReadLinkData;
		WriteLinkData : WriteLinkData;
		ExportEventData : ExportEventData;
		x : UINT;
		y : UINT;
	END_STRUCT;
	exCoreInternalRecordType : 	STRUCT 
		CRC : USINT;
		FileName : STRING[80]; (*ID of the event*)
		EventType : exCoreInternalRecordEnum;
		TimeStart : DATE_AND_TIME; (*Event start*)
		TimeEnd : DATE_AND_TIME; (*Event end*)
		ShiftName : STRING[20]; (*Shift name*)
		JobName : STRING[20]; (*Job name.*)
		TotalTime : exAssetIntTimeType; (*Total time since this job started*)
		ScheduledDowntime : exAssetIntTimeType; (*Scheduled downtime since this job started*)
		UnscheduledDowntime : exAssetIntTimeType; (*Unsheduled downtime since this job started*)
		Uptime : exAssetIntTimeType; (*Uptime since this job started*)
		NominalProductionTime : exAssetIntTimeType; (*Time of production at nominal speed since this job started*)
		GoodProductionTime : exAssetIntTimeType; (*Time of good production since this job started*)
		ScheduledDowntimeRate : REAL; (*Percentage of scheduled downtime [%] since this job started*)
		UnscheduledDowntimeRate : REAL; (*Percentage of unscheduled downtime [%] since this job started*)
		NominalProductionTimeRate : REAL; (*Percentage of nominal speed running time[%] since this job started*)
		TargetPieces : UDINT; (*Specifies the target quantity of products to be produced by the machine at nominal speed*)
		TotalPieces : UDINT; (*Counter for total products since this job started*)
		GoodPieces : UDINT; (*Counter for good products since this job started*)
		RejectPieces : UDINT; (*Counter for reject products since this job started*)
		BadPieceRate : REAL; (*Percentage of bad products [%] since this job started*)
		CurrentProductionRate : REAL; (*Production rate since this job started [products / h]*)
		CurrentUser : STRING[50]; (*Currently active user*)
		AdditionalData : STRING[EVENT_ADDITONAL_DATA_LEN]; (*Additional data information*)
	END_STRUCT;
	exCoreInternalRecordEnum : 
		(
		RecordTypeJob := 0,
		RecordTypeShift := 1,
		RecordTypeNoShift := 2,
		RecordTypeUptime := 3,
		RecordTypeDowntimeScheduled := 4,
		RecordTypeDowntimeUnscheduled := 5,
		RecordTypeUserChange := 6,
		RecordTypeTimeline := 10
		);
	exCoreInternalExportEnum : 
		(
		ExportTypeJob,
		ExportTypeShift,
		ExportTypeTimeline
		);
	exConfigInternalDataType : 	STRUCT 
		State : exAssetIntStateEnum;
		StateError : exAssetIntStateEnum := exASSETINT_STATE_NONE;
		ReadConfiguration : ReadConfiguration;
		WriteConfiguration : WriteConfiguration;
	END_STRUCT;
	exUIInternalDataType : 	STRUCT 
		RecordStart : DINT; (*Visible list is starting from this index*)
		RecordCount : UINT; (*Total number of items*)
		RecordCountOld : UINT; (*Old record number is required for DESC list*)
		RecordData : exCoreInternalRecordType;
		TimeSeconds : UDINT;
		TimeLongest : UDINT;
		SortingStartTimeOld : exAssetIntUISortingEnum := exASSETINT_SORTING_ASC;
		DT_TO_DTStructure_0 : DTStructure;
		x : UDINT;
		y : UDINT;
		State : exAssetIntStateEnum;
		StateError : exAssetIntStateEnum := exASSETINT_STATE_NONE;
	END_STRUCT;
	exAssetIntLinkType : 	STRUCT 
		Version : USINT; (*Data structure version*)
		MemoryDb : UDINT; (*Database memory*)
		MemoryJob : UDINT; (*Job data memory*)
		MemoryShift : UDINT; (*Shift data memory*)
		MemoryTimeline : UDINT; (*Timeline data memory*)
		StatsLastCall : DTStructure; (*Date and time when the stats were last calculated*)
		Configuration : exAssetIntCoreConfigType; (*Configuration structure*)
		RecordCount : UINT; (*Number of total records*)
		IsCoreActive : BOOL; (*Core function block is ready*)
		RefreshJobUI : BOOL; (*Update job stats in UI*)
		RefreshShiftUI : BOOL; (*Update shift stats in UI*)
		RefreshTimelineUI : BOOL; (*Update timeline stats in UI*)
		ShiftStatistics : exAssetIntShiftStatisticsType; (*Current shift stats*)
		ShiftTotalTime : LREAL; (*Milliseconds the job is running*)
		ShiftDowntimeScheduled : UDINT; (*Milliseconds of scheduled downtime*)
		ShiftDowntimeUnscheduled : UDINT; (*Milliseconds of unscheduled downtime*)
		ShiftSecondsToEnd : UDINT;
		JobStatistics : exAssetIntJobStatisticsType; (*Current job stats*)
		JobTotalTime : LREAL; (*Milliseconds the job is running*)
		JobDowntimeScheduled : UDINT; (*Milliseconds of scheduled downtime*)
		JobDowntimeUnscheduled : UDINT; (*Milliseconds of unscheduled downtime*)
		ShiftId : SINT := -1; (*Index of shift configuration*)
		ProductionStateStart : DATE_AND_TIME; (*Current state beginning*)
		ProductionState : exAssetIntUIProductionStateEnum; (*Current state*)
		ProductionTotalTime : LREAL; (*Milliseconds the state is running*)
		ProductionUserName : STRING[50]; (*Currently active user*)
		ProductionShiftName : STRING[20]; (*ShiftName for this timeline*)
		ProductionJobName : STRING[20]; (*Job name for this timeline*)
		ProductionDowntime : exAssetIntDowntimeEnum; (*Downtime for this timeline*)
		ProductionDowntimeReason : STRING[50]; (*Donwtime reason for this timeline*)
	END_STRUCT;
END_TYPE

(*Enum type*)

TYPE
	exAssetIntStateEnum : 
		(
		exASSETINT_STATE_INIT_1 := 1, (*Init state*)
		exASSETINT_STATE_INIT_2 := 2, (*Init state*)
		exASSETINT_STATE_INIT_3 := 3, (*Init state*)
		exASSETINT_STATE_INIT_4 := 4, (*Init state*)
		exASSETINT_STATE_INIT_5 := 5, (*Init state*)
		exASSETINT_STATE_IDLE := 10, (*Wait for command and collect data*)
		exASSETINT_STATE_STORE_EVENT := 20, (*Store new event data*)
		exASSETINT_STATE_EXPORT_EVENTS := 21, (*Export all events*)
		exASSETINT_STATE_UI_BUFFER := 30, (*Copy job data from global buffer to UI buffer*)
		exASSETINT_STATE_UI_DATA := 31, (*Generate UI data*)
		exASSETINT_STATE_SAVE_CFG := 40, (*Save configuration*)
		exASSETINT_STATE_LOAD_CFG := 41, (*Load configuration*)
		exASSETINT_STATE_SAVE_LINK := 50, (*Save internal data*)
		exASSETINT_STATE_LOAD_LINK := 51, (*Load internal data*)
		exASSETINT_STATE_ERROR := 90, (*Error state*)
		exASSETINT_STATE_NONE := 99 (*Empty state*)
		);
	exAssetIntLogLevelEnum : 
		(
		exASSETINT_LOG_OFF := 0, (*Logging is disabled*)
		exASSETINT_LOG_ERROR := 1, (*Only log errors*)
		exASSETINT_LOG_INFO := 2, (*Also log information*)
		exASSETINT_LOG_ALL := 3 (*Log everything*)
		);
	exAssetIntBufferOffsets : 
		(
		exASSETINT_BUFFER_MEMORY := 0
		);
	exAssetIntUIStatusEnum : 
		(
		exASSETINT_UI_STATUS_IDLE := 0, (*Status: Idle, Waiting for command*)
		exASSETINT_UI_STATUS_UPDATE := 1, (*Status: Updating UIConnect structer*)
		exASSETINT_UI_STATUS_FILTER := 2 (*Status: Showing filter-dialog*)
		);
	exAssetIntMemoryEnum : 
		(
		exASSETINT_MEM_DB := 0, (*Database memory*)
		exASSETINT_MEM_JOB := 1, (*Job working memory*)
		exASSETINT_MEM_SHIFT := 2, (*Shift working memory*)
		exASSETINT_MEM_TIMELINE := 3 (*Timeline working memory*)
		);
	exAssetIntDowntimeEnum : 
		(
		exASSETINT_NO_DOWNTIME := 0, (*No downtime active = uptime*)
		exASSETINT_SCHEDULED_DOWNTIME := 1, (*Additional scheduled downtime (e.g. monthly maintenance)*)
		exASSETINT_UNSCHEDULED_DOWNTIME := 2 (*Unscheduled downtime (e.g. machine fault)*)
		);
	exComSeveritiesEnum : 
		(
		exCOM_SEV_SUCCESS := 0, (*Success - no error*)
		exCOM_SEV_INFORMATIONAL := 1, (*Severity: Informational*)
		exCOM_SEV_WARNING := 2, (*Severity: Warning*)
		exCOM_SEV_ERROR := 3 (*Severity: Error*)
		);
END_TYPE

(*Config type*)

TYPE
	exAssetIntCoreConfigType : 	STRUCT 
		CalculationTimeBase : UDINT := 1000; (*Cycle time for calculating the current production rate*)
		Shifts : ARRAY[0..4]OF exAssetIntShiftParType := [5(0)]; (*Shift schedule in detailed*)
		Export : exAssetIntExportType; (*Configuration for export*)
	END_STRUCT;
	exAssetIntExportType : 	STRUCT 
		JobStatistics : BOOL := TRUE; (*Export the job statistics or not.*)
		JobStatisticsFileNamePattern : STRING[50] := 'JobStatistics_%Y_%m_%d_%H_%M.csv'; (*Pattern for export job statistics file.*)
		ShiftStatistics : BOOL := TRUE; (*Export the shift statistics or not.*)
		ShiftStatisticsFileNamePattern : STRING[50] := 'ShiftStatistics_%Y_%m_%d_%H_%M.csv'; (*Pattern for export shift statistics file.*)
		Timeline : BOOL := TRUE; (*Export the timeline statistics or not.*)
		TimelineFileNamePattern : STRING[50] := 'Timeline_%Y_%m_%d_%H_%M.csv'; (*Pattern for export timeline  file.*)
		TimestampPattern : STRING[50] := '%Y-%m-%d %H:%M:%S'; (*Timestamp pattern in exported file.*)
		DecimalDigits : UINT := 2; (*Specifies how many decimal positions are saved*)
		ColumnSeparator : STRING[1] := ','; (*Delimiter used to split up PVs in the .csv file*)
		DecimalMark : STRING[1] := '.'; (*Character to be used for the decimal separator*)
	END_STRUCT;
	exAssetIntShiftParType : 	STRUCT 
		Name : STRING[20]; (*Shift name*)
		TotalTime : exAssetIntTimeSlotType; (*Total time of one shift*)
		ScheduledDowntime : ARRAY[0..9]OF exAssetIntScheduledDowntimeType; (*Scheduled downtime in one shift*)
	END_STRUCT;
	exAssetIntTimeSlotType : 	STRUCT 
		Start : TIME_OF_DAY; (*Start time.*)
		End : TIME_OF_DAY; (*End time*)
	END_STRUCT;
	exAssetIntScheduledDowntimeType : 	STRUCT 
		Reason : STRING[50]; (*Downtime reason*)
		Start : TIME_OF_DAY; (*Start time.*)
		End : TIME_OF_DAY; (*End time*)
	END_STRUCT;
END_TYPE

(*Parameter type*)

TYPE
	exAssetIntParType : 	STRUCT 
		NominalProductionRate : REAL := 0.0; (*Nominal production rate [products / h]*)
		Job : STRING[20] := 'Job1'; (*Currently active production job*)
		CurrentUser : STRING[50]; (*Currently logged in user*)
		AdditionalData : STRING[255]; (*Additional data to be logged*)
	END_STRUCT;
END_TYPE

(*UI type*)

TYPE
	exAssetIntUITrendType : 	STRUCT 
		SaexleData : ARRAY[0..365]OF REAL; (*FB->VC:Saexle data for trend data*)
		SaexleRate : UDINT; (*FB->VC:Saexle rate datapoint for trend data*)
		SaexleCount : UDINT; (*FB->VC:Saexle count datapoint for trend data*)
		SaexleDateTime : DATE_AND_TIME; (*FB->VC:Saexle DataTime datapoint for trend data*)
		MinValue : REAL; (*FB->VC:Min.value datapoint for trend data*)
		MaxValue : REAL; (*FB->VC:Max.value datapoint for trend data*)
		HideCurve : INT; (*FB->VC:Hide the curve if set to 1, status datapoint for trend curve*)
		TimeZoom : REAL; (*FB->VC:Zoom datapoint for trend time scale.*)
		TimeScroll : REAL; (*FB->VC:Scoll datapoint for trend time scale.*)
	END_STRUCT;
	exAssetIntUIShiftListType : 	STRUCT 
		ShiftNames : ARRAY[0..5]OF STRING[20]; (*FB->VC: Shift names, *)
		SelectedIndex : UINT; (*VC->FB: Selection index for ShiftList.*)
		MaxSelection : USINT;
	END_STRUCT;
	exAssetIntTrendUIConnectType : 	STRUCT 
		Status : exAssetIntUIStatusEnum; (*Status of UI function block*)
		ScheduledDowntimeRate : exAssetIntUITrendType; (*Trend for scheduled downtime rate*)
		UnscheduledDowntimeRate : exAssetIntUITrendType; (*Trend for unscheduled downtime rate*)
		NominalProductionRate : exAssetIntUITrendType; (*Trend for nominal production rate*)
		BadPieceRate : exAssetIntUITrendType; (*Trend for bad piece rate*)
		ShiftList : exAssetIntUIShiftListType; (*Determine which shift in the day is shown in the trend*)
		Filter : exAssetIntUIFilterType; (*Output filter.*)
	END_STRUCT;
	exAssetIntUITimelineOutputType : 	STRUCT 
		StartTime : ARRAY[0..UI_TIMELINE_IDX]OF DATE_AND_TIME; (*FB->VC:Start time of this state*)
		ShiftName : ARRAY[0..UI_TIMELINE_IDX]OF STRING[20]; (*FB->VC:Shift name*)
		JobName : ARRAY[0..UI_TIMELINE_IDX]OF STRING[20]; (*FB->VC:Job name*)
		ProductionState : ARRAY[0..UI_TIMELINE_IDX]OF exAssetIntUIProductionStateEnum; (*FB->VC:Production state*)
		Reason : ARRAY[0..UI_TIMELINE_IDX]OF STRING[50]; (*FB->VC:Reason of this state*)
		Duration : ARRAY[0..UI_TIMELINE_IDX]OF exAssetIntTimeType; (*FB->VC:Duration of this state*)
		DurationBar : ARRAY[0..UI_TIMELINE_IDX]OF exAssetIntUITimeBargraphType; (*FB->VC:Duration of this state in a graphic way*)
		RangeStart : REAL; (*Displayed range: Start %*)
		RangeEnd : REAL; (*Displayed range: End %*)
		PageUp : BOOL; (*Command: Page Up (Scroll Up)*)
		StepUp : BOOL; (*Command: Line Up (Scroll Up)*)
		StepDown : BOOL; (*Command: Line Down (Scroll Down)*)
		PageDown : BOOL; (*Command: Page Down (Scroll Down)*)
	END_STRUCT;
	exAssetIntUITimeBargraphType : 	STRUCT 
		Duration : UDINT; (*FB->VC:EndValue(lenth) of the scale*)
		Color : UDINT; (*FB->VC:ColorDatapoint of the scale*)
	END_STRUCT;
	exAssetIntTimelineUIConnectType : 	STRUCT 
		Status : exAssetIntUIStatusEnum; (*Status of UI function block*)
		Output : exAssetIntUITimelineOutputType; (*Output information.*)
		Filter : exAssetIntUIFilterType; (*Output filter.*)
	END_STRUCT;
	exAssetIntTimeType : 	STRUCT 
		Hours : UDINT; (*Numbers of hours*)
		Minutes : USINT; (*Numbers of minutes within an hour*)
		Seconds : USINT; (*Numbers of seconds within a minute*)
	END_STRUCT;
	exAssetIntShiftListUIConnectType : 	STRUCT 
		Status : exAssetIntUIStatusEnum; (*Status of UI function block*)
		Output : exAssetIntUIShiftListOutputType; (*Output information.*)
		Filter : exAssetIntUIFilterType; (*Output filter.*)
	END_STRUCT;
	exAssetIntUIShiftListOutputType : 	STRUCT 
		StartTime : ARRAY[0..UI_SHIFT_LIST_IDX]OF DATE_AND_TIME; (*Start time list*)
		EndTime : ARRAY[0..UI_SHIFT_LIST_IDX]OF DATE_AND_TIME; (*End time list*)
		ShiftName : ARRAY[0..UI_SHIFT_LIST_IDX]OF STRING[20]; (*Shift ID list*)
		CurrentUser : ARRAY[0..UI_SHIFT_LIST_IDX]OF STRING[50]; (*Currently active user*)
		AdditionalData : ARRAY[0..UI_SHIFT_LIST_IDX]OF STRING[255]; (*Additional data information*)
		TargetPieces : ARRAY[0..UI_SHIFT_LIST_IDX]OF UDINT; (*Target pieces list*)
		TotalPieces : ARRAY[0..UI_SHIFT_LIST_IDX]OF UDINT; (*Total pieces list*)
		GoodPieces : ARRAY[0..UI_SHIFT_LIST_IDX]OF UDINT; (*Good pieces list*)
		RejectPieces : ARRAY[0..UI_SHIFT_LIST_IDX]OF UDINT; (*Reject pieces list*)
		BadPieceRate : ARRAY[0..UI_SHIFT_LIST_IDX]OF REAL; (*bad piece rate list*)
		TotalTime : ARRAY[0..UI_SHIFT_LIST_IDX]OF exAssetIntTimeType; (*Total time list*)
		ScheduledDowntime : ARRAY[0..UI_SHIFT_LIST_IDX]OF exAssetIntTimeType; (*Scheduled Downtime list*)
		UnscheduledDowntime : ARRAY[0..UI_SHIFT_LIST_IDX]OF exAssetIntTimeType; (*Unscheduled Downtime list*)
		Uptime : ARRAY[0..UI_SHIFT_LIST_IDX]OF exAssetIntTimeType; (*Uptime list*)
		GoodProductionTime : ARRAY[0..UI_SHIFT_LIST_IDX]OF exAssetIntTimeType; (*Good production time list*)
		NominalProductionTime : ARRAY[0..UI_SHIFT_LIST_IDX]OF exAssetIntTimeType; (*nominal production time list*)
		NominalProductionRate : ARRAY[0..UI_SHIFT_LIST_IDX]OF REAL; (*nominal production rate list*)
		ShiftProductionRate : ARRAY[0..UI_SHIFT_LIST_IDX]OF REAL; (*Shift production rate list*)
		ScheduledDowntimeRate : ARRAY[0..UI_SHIFT_LIST_IDX]OF REAL; (*scheduled downtime rate list*)
		UnscheduledDowntimeRate : ARRAY[0..UI_SHIFT_LIST_IDX]OF REAL; (*unscheduled downtime rate list*)
		ProductionRate : ARRAY[0..UI_SHIFT_LIST_IDX]OF REAL; (*current production rate list*)
		RangeStart : REAL; (*Displayed range: Start %*)
		RangeEnd : REAL; (*Displayed range: End %*)
		PageUp : BOOL; (*Command: Page Up (Scroll Up)*)
		StepUp : BOOL; (*Command: Line Up (Scroll Up)*)
		StepDown : BOOL; (*Command: Line Down (Scroll Down)*)
		PageDown : BOOL; (*Command: Page Down (Scroll Down)*)
		IdealProductionRate : ARRAY[0..UI_SHIFT_LIST_IDX]OF REAL; (*ideal production rate list*)
		JobName : ARRAY[0..UI_SHIFT_LIST_IDX]OF STRING[20]; (*Job name list*)
	END_STRUCT;
	exAssetIntUIShiftListJobType : 	STRUCT  (*Jobs within one shift*)
		Name : ARRAY[0..9]OF STRING[20]; (*Name of the job*)
	END_STRUCT;
	exAssetIntListUISetupType : 	STRUCT 
		ScrollWindow : USINT := 0; (*Scroll Window (overlap for PageUp/Down)*)
		SortingStartTime : exAssetIntUISortingEnum := exASSETINT_SORTING_DESC;
	END_STRUCT;
	exAssetIntJobListUIConnectType : 	STRUCT 
		Status : exAssetIntUIStatusEnum; (*Status of UI function block*)
		Output : exAssetIntUIJobListOutputType; (*Output information.*)
		Filter : exAssetIntUIFilterType; (*Output filter.*)
	END_STRUCT;
	exAssetIntUIJobListOutputType : 	STRUCT 
		JobStartTime : ARRAY[0..UI_JOB_LIST_IDX]OF DATE_AND_TIME; (*Job start time list*)
		JobEndTime : ARRAY[0..UI_JOB_LIST_IDX]OF DATE_AND_TIME; (*Job end time list*)
		JobName : ARRAY[0..UI_JOB_LIST_IDX]OF STRING[20]; (*Job name list*)
		CurrentUser : ARRAY[0..UI_JOB_LIST_IDX]OF STRING[50]; (*Currently active user*)
		AdditionalData : ARRAY[0..UI_JOB_LIST_IDX]OF STRING[255]; (*Additional data information*)
		TotalPieces : ARRAY[0..UI_JOB_LIST_IDX]OF UDINT; (*Total pieces list*)
		GoodPieces : ARRAY[0..UI_JOB_LIST_IDX]OF UDINT; (*Good pieces list*)
		RejectPieces : ARRAY[0..UI_JOB_LIST_IDX]OF UDINT; (*Reject pieces list*)
		BadPieceRate : ARRAY[0..UI_JOB_LIST_IDX]OF REAL; (*bad piece rate list*)
		TotalTime : ARRAY[0..UI_JOB_LIST_IDX]OF exAssetIntTimeType; (*Total time list*)
		ScheduledDowntime : ARRAY[0..UI_JOB_LIST_IDX]OF exAssetIntTimeType; (*Scheduled Downtime list*)
		UnscheduledDowntime : ARRAY[0..UI_JOB_LIST_IDX]OF exAssetIntTimeType; (*Unscheduled Downtime list*)
		Uptime : ARRAY[0..UI_JOB_LIST_IDX]OF exAssetIntTimeType; (*Uptime list*)
		GoodProductionTime : ARRAY[0..UI_JOB_LIST_IDX]OF exAssetIntTimeType; (*Good production time list*)
		NominalProductionTime : ARRAY[0..UI_JOB_LIST_IDX]OF exAssetIntTimeType; (*nominal production time list*)
		NominalProductionRate : ARRAY[0..UI_JOB_LIST_IDX]OF REAL; (*nominal production rate list*)
		ScheduledDowntimeRate : ARRAY[0..UI_JOB_LIST_IDX]OF REAL; (*scheduled downtime rate list*)
		UnscheduledDowntimeRate : ARRAY[0..UI_JOB_LIST_IDX]OF REAL; (*unscheduled downtime rate list*)
		ProductionRate : ARRAY[0..UI_JOB_LIST_IDX]OF REAL; (*current production rate list*)
		RangeStart : REAL; (*Displayed range: Start %*)
		RangeEnd : REAL; (*Displayed range: End %*)
		PageUp : BOOL; (*Command: Page Up (Scroll Up)*)
		StepUp : BOOL; (*Command: Line Up (Scroll Up)*)
		StepDown : BOOL; (*Command: Line Down (Scroll Down)*)
		PageDown : BOOL; (*Command: Page Down (Scroll Down)*)
		ShiftName : ARRAY[0..UI_JOB_LIST_IDX]OF STRING[20]; (*Shift ID list*)
	END_STRUCT;
	exAssetIntUISortingEnum : 
		(
		exASSETINT_SORTING_ASC := 0, (*Sorting ascending*)
		exASSETINT_SORTING_DESC := 1 (*Sorting descending*)
		);
	exAssetIntUIProductionStateEnum : 
		(
		exASSETINT_STATE_NO_SHIFT_ACTIVE := 0, (*Inactive state*)
		exASSETINT_STATE_UPTIME := 1, (*Uptime state*)
		exASSETINT_STATE_SCHDL_DOWNTIME := 2, (*Scheduled downtime state*)
		exASSETINT_STATE_UNSCH_DOWNTIME := 3, (*Unscheduled downtime state*)
		exASSETINT_STATE_USER_CHANGE := 4 (*User change*)
		);
	exAssetIntUICurrDTFilterType : 	STRUCT 
		Enable : BOOL; (*Enable Filter*)
		DateTime : DATE_AND_TIME; (*Date and time of filter*)
	END_STRUCT;
	exAssetIntUISetDTFilterType : 	STRUCT 
		Enable : BOOL; (*Enable Filter*)
		Year : UINT; (*Date&Time: Year*)
		Month : USINT; (*Date&Time: Month*)
		Day : USINT; (*Date&Time: Day*)
		Hour : USINT; (*Date&Time: Hour*)
		Minute : USINT; (*Date&Time: Minute*)
	END_STRUCT;
	exAssetIntUIFilterDialogType : 	STRUCT 
		LayerStatus : UINT := UI_LAYER_HIDE; (*			Filter.Dialog.LayerStatus := UI_LAYER_HIDE;
*)
		From : exAssetIntUISetDTFilterType; (*Display entries from given date&time*)
		Until : exAssetIntUISetDTFilterType; (*Display entries until given date&time*)
		Confirm : BOOL;
		Cancel : BOOL;
	END_STRUCT;
	exAssetIntUIFilterType : 	STRUCT 
		ShowDialog : BOOL;
		Dialog : exAssetIntUIFilterDialogType; (*Dialog-data to change filter-settings*)
		Current : exAssetIntUICurrentFilterType; (*Currently active filter settings*)
		DefaultLayerStatus : UINT;
	END_STRUCT;
	exAssetIntUICurrentFilterType : 	STRUCT 
		From : exAssetIntUICurrDTFilterType; (*Starting time of current filter*)
		Until : exAssetIntUICurrDTFilterType; (*End time of current filter*)
	END_STRUCT;
END_TYPE

(*Info type*)

TYPE
	exAssetIntJobStatisticsType : 	STRUCT 
		JobName : STRING[20]; (*Job name.*)
		StartTime : DATE_AND_TIME;
		TotalTime : exAssetIntTimeType; (*Total time since this job started*)
		ScheduledDowntime : exAssetIntTimeType; (*Scheduled downtime since this job started*)
		UnscheduledDowntime : exAssetIntTimeType; (*Unsheduled downtime since this job started*)
		Uptime : exAssetIntTimeType; (*Uptime since this job started*)
		NominalProductionTime : exAssetIntTimeType; (*Time of production at nominal speed since this job started*)
		GoodProductionTime : exAssetIntTimeType; (*Time of good production since this job started*)
		ScheduledDowntimeRate : REAL; (*Percentage of scheduled downtime [%] since this job started*)
		UnscheduledDowntimeRate : REAL; (*Percentage of unscheduled downtime [%] since this job started*)
		NominalProductionTimeRate : REAL; (*Percentage of nominal speed running time[%] since this job started*)
		TotalPieces : UDINT; (*Counter for total products since this job started*)
		GoodPieces : UDINT; (*Counter for good products since this job started*)
		RejectPieces : UDINT; (*Counter for reject products since this job started*)
		BadPieceRate : REAL; (*Percentage of bad products [%] since this job started*)
		CurrentProductionRate : REAL; (*Production rate since this job started [products / h]*)
		CurrentUser : STRING[50]; (*Currently active user*)
		AdditionalData : STRING[EVENT_ADDITONAL_DATA_LEN]; (*Additional data information*)
	END_STRUCT;
	exAssetIntShiftStatisticsType : 	STRUCT 
		ShiftName : STRING[20]; (*Shift name.*)
		StartTime : DATE_AND_TIME;
		TotalTime : exAssetIntTimeType; (*Total time since this shift started*)
		ScheduledDowntime : exAssetIntTimeType; (*Scheduled downtime since this shift started*)
		UnscheduledDowntime : exAssetIntTimeType; (*Unsheduled downtime since this shift started*)
		Uptime : exAssetIntTimeType; (*Uptime since this shift started*)
		GoodProductionTime : exAssetIntTimeType; (*Time of good production since this shift started*)
		NominalProductionTime : exAssetIntTimeType; (*Time of production at nominal speed since this shift started*)
		ScheduledDowntimeRate : REAL; (*Percentage of scheduled downtime [%] since this shift started*)
		UnscheduledDowntimeRate : REAL; (*Percentage of unscheduled downtime [%] since this shift started*)
		NominalProductionTimeRate : REAL; (*Percentage of nominal speed running time[%] since this shift started*)
		TargetPieces : UDINT; (*Counter for target products since this shift started*)
		TotalPieces : UDINT; (*Counter for total products since this shift started*)
		GoodPieces : UDINT; (*Counter for good products since this shift started*)
		RejectPieces : UDINT; (*Counter for reject products since this shift started*)
		BadPieceRate : REAL; (*Percentage of bad products [%] since this shift started*)
		CurrentProductionRate : REAL; (*Production rate since this shift started [products / h]*)
		CurrentUser : STRING[50]; (*Currently active user*)
		AdditionalData : STRING[255]; (*Additional data information*)
		IdealProductionRate : REAL; (*Ideal production rate*)
	END_STRUCT;
	exAssetIntCoreInfoType : 	STRUCT 
		ShiftStatistics : exAssetIntShiftStatisticsType; (*Shift statistics*)
		JobStatistics : exAssetIntJobStatisticsType; (*Job statistics*)
		Diag : exAssetIntDiagType; (*Additional diagnostic information*)
	END_STRUCT;
	exAssetIntInfoType : 	STRUCT 
		Diag : exAssetIntDiagType; (*Additional diagnostic information*)
	END_STRUCT;
	exAssetIntDiagType : 	STRUCT 
		StatusID : exAssetIntStatusIDType; (*Segmented StatusID output*)
	END_STRUCT;
	exAssetIntStatusIDType : 	STRUCT 
		ID : exAssetIntErrorEnum; (*StatusID as enumerator*)
		Severity : exComSeveritiesEnum; (*Severity of the error*)
		Code : UINT; (*Error code*)
	END_STRUCT;
END_TYPE
