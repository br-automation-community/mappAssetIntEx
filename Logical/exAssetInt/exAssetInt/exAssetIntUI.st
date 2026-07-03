// -------------------------------------------------------------------------------------------
// File version 1006
// -------------------------------------------------------------------------------------------
// Job UI function block
FUNCTION_BLOCK exAssetIntJobListUI
	// -------------------------------------------------------------------------------------------
	// Reset everything when enable is false
	IF NOT Enable THEN
		IF ADR(UIConnect) <> 0 THEN
			UIConnect.Filter.Dialog.LayerStatus := UI_LAYER_HIDE;
		END_IF
		StatusID := ERR_FUB_ENABLE_FALSE;
		Active := FALSE;
		Internal.State := exASSETINT_STATE_INIT_1;
		CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('function block disabled'), Logger);
		RETURN;
	END_IF
	
	CASE Internal.State OF

		// -------------------------------------------------------------------------------------------
		// Wait for enable
		exASSETINT_STATE_INIT_1:
			IF Enable THEN
				CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('function block enabled'), Logger);
				
				// Check prerequisites, exLink and buffers
				IF NOT exAssetIntCheckPreq(exLink, ADR(UIConnect), Logger, ADR(Internal.State), ADR(StatusID), ADR(Info.Diag.StatusID)) THEN
					RETURN;
				END_IF

				// Reset error and status
				brsmemset(ADR(Info.Diag), 0, SIZEOF(Info.Diag));
				Error := FALSE;
				StatusID := ERR_OK;
				Internal.SortingStartTimeOld := exASSETINT_SORTING_ASC;
				
				// Reset filter settings
				exAssetIntFilterReset(ADR(UIConnect.Filter));
			
				Internal.State := exASSETINT_STATE_IDLE;
			END_IF

			// -------------------------------------------------------------------------------------------
			// Wait for new event
		exASSETINT_STATE_IDLE:
			// Set status
			UIConnect.Status := exASSETINT_UI_STATUS_IDLE;
			Active := TRUE;

			// Handle dialog window
			Internal.State := exAssetIntFilterListUI(ADR(UIConnect.Filter), ADR(UIConnect.Status), Logger, Internal.State);
			
			// Handle sorting direction change
			IF UISetup.SortingStartTime <> Internal.SortingStartTimeOld AND exLink.RecordCount > 0 THEN
				Internal.State := exASSETINT_STATE_UI_BUFFER;
			END_IF
			Internal.SortingStartTimeOld := UISetup.SortingStartTime;
			
			// Handle page up and down
			Internal.State := exAssetIntScrollListUI(Internal.RecordCount, UI_JOB_LIST_IDX + 1, ADR(UIConnect.Output.PageUp), ADR(UIConnect.Output.PageDown), ADR(UIConnect.Output.StepUp), ADR(UIConnect.Output.StepDown), ADR(Internal.RecordStart), ADR(UIConnect.Output.RangeStart), ADR(UIConnect.Output.RangeEnd), Internal.State);

			// Wait for core task to call update command
			IF exLink.RefreshJobUI AND exLink.RecordCount > 0 THEN			
				Internal.State := exASSETINT_STATE_UI_BUFFER;					
			END_IF
			
			// -------------------------------------------------------------------------------------------
			// Copy job data from global buffer to job buffer
		exASSETINT_STATE_UI_BUFFER:
			// Set status
			CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('refresh job data'), Logger);
			UIConnect.Status := exASSETINT_UI_STATUS_UPDATE;

			// Generate job data
			Internal.RecordCount := exAssetIntBufferUI(exLink.MemoryJob, exLink, UISetup.SortingStartTime, UIConnect.Filter, RecordTypeJob);
			
			Internal.State := exASSETINT_STATE_UI_DATA;	

		// -------------------------------------------------------------------------------------------
		// Transfer data from buffer to list array
		exASSETINT_STATE_UI_DATA:			
						
			Internal.x := 0;
			brsmemset(ADR(UIConnect.Output), 0, SIZEOF(UIConnect.Output));
			REPEAT
				brsmemcpy(ADR(Internal.RecordData), exLink.MemoryJob + (Internal.x + Internal.RecordStart)*SIZEOF(Internal.RecordData), SIZEOF(Internal.RecordData));
				
				UIConnect.Output.JobStartTime[Internal.x] := Internal.RecordData.TimeStart;
				UIConnect.Output.JobEndTime[Internal.x] := Internal.RecordData.TimeEnd;
				UIConnect.Output.JobName[Internal.x] := Internal.RecordData.JobName;
				UIConnect.Output.CurrentUser[Internal.x] := Internal.RecordData.CurrentUser;
				UIConnect.Output.AdditionalData[Internal.x] := Internal.RecordData.AdditionalData;
				UIConnect.Output.TotalPieces[Internal.x] := Internal.RecordData.TotalPieces;
				UIConnect.Output.GoodPieces[Internal.x] := Internal.RecordData.GoodPieces;
				UIConnect.Output.RejectPieces[Internal.x] := Internal.RecordData.RejectPieces;
				UIConnect.Output.BadPieceRate[Internal.x] := Internal.RecordData.BadPieceRate;
				UIConnect.Output.TotalTime[Internal.x] := Internal.RecordData.TotalTime;
				UIConnect.Output.ScheduledDowntime[Internal.x] := Internal.RecordData.ScheduledDowntime;
				UIConnect.Output.UnscheduledDowntime[Internal.x] := Internal.RecordData.UnscheduledDowntime;
				UIConnect.Output.Uptime[Internal.x] := Internal.RecordData.Uptime;
				UIConnect.Output.GoodProductionTime[Internal.x] := Internal.RecordData.GoodProductionTime;
				UIConnect.Output.NominalProductionTime[Internal.x] := Internal.RecordData.NominalProductionTime;
				UIConnect.Output.NominalProductionRate[Internal.x] := Internal.RecordData.NominalProductionTimeRate;
				UIConnect.Output.UnscheduledDowntimeRate[Internal.x] := Internal.RecordData.UnscheduledDowntimeRate;
				UIConnect.Output.ProductionRate[Internal.x] := Internal.RecordData.CurrentProductionRate;
				UIConnect.Output.ShiftName[Internal.x] := Internal.RecordData.ShiftName;

				Internal.x := Internal.x + 1;
				
				UNTIL (Internal.x > UI_JOB_LIST_IDX) OR (Internal.x + Internal.RecordStart >= Internal.RecordCount)
			END_REPEAT;
							
			exLink.RefreshJobUI := FALSE;

			CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('refresh job done'), Logger);
			Internal.State := exASSETINT_STATE_IDLE;	
			
			// -------------------------------------------------------------------------------------------
		// Error state
		exASSETINT_STATE_ERROR:		
			IF EDGEPOS(ErrorReset) THEN
				Internal.StateError := exASSETINT_STATE_NONE;
				Internal.State := exASSETINT_STATE_INIT_1;
			END_IF
	END_CASE;
END_FUNCTION_BLOCK

// -------------------------------------------------------------------------------------------
// Shift UI function block
FUNCTION_BLOCK exAssetIntShiftListUI
	// -------------------------------------------------------------------------------------------
	// Reset everything when enable is false
	IF NOT Enable THEN
		IF ADR(UIConnect) <> 0 THEN
			UIConnect.Filter.Dialog.LayerStatus := UI_LAYER_HIDE;
		END_IF
		StatusID := ERR_FUB_ENABLE_FALSE;
		Active := FALSE;
		Internal.State := exASSETINT_STATE_INIT_1;
		CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('function block disabled'), Logger);
		RETURN;
	END_IF
	
	CASE Internal.State OF

		// -------------------------------------------------------------------------------------------
		// Wait for enable
		exASSETINT_STATE_INIT_1:
			IF Enable THEN
				CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('function block enabled'), Logger);

				// Check prerequisites, exLink and buffers
				IF NOT exAssetIntCheckPreq(exLink, ADR(UIConnect), Logger, ADR(Internal.State), ADR(StatusID), ADR(Info.Diag.StatusID)) THEN
					RETURN;
				END_IF

				// Reset error and status
				Error := FALSE;
				StatusID := ERR_OK;
				Internal.SortingStartTimeOld := exASSETINT_SORTING_ASC;
				
				// Reset filter settings
				exAssetIntFilterReset(ADR(UIConnect.Filter));				

				Internal.State := exASSETINT_STATE_IDLE;
			END_IF

			// -------------------------------------------------------------------------------------------
			// Wait for new event
		exASSETINT_STATE_IDLE:	
			// Set status
			UIConnect.Status := exASSETINT_UI_STATUS_IDLE;
			Active := TRUE;

			// Handle dialog window
			Internal.State := exAssetIntFilterListUI(ADR(UIConnect.Filter), ADR(UIConnect.Status), Logger, Internal.State);
			
			// Handle sorting direction change
			IF UISetup.SortingStartTime <> Internal.SortingStartTimeOld AND exLink.RecordCount > 0 THEN
				Internal.State := exASSETINT_STATE_UI_BUFFER;
			END_IF
			Internal.SortingStartTimeOld := UISetup.SortingStartTime;
			
			// Handle page up and down
			Internal.State := exAssetIntScrollListUI(Internal.RecordCount, UI_TIMELINE_IDX + 1, ADR(UIConnect.Output.PageUp), ADR(UIConnect.Output.PageDown), ADR(UIConnect.Output.StepUp), ADR(UIConnect.Output.StepDown), ADR(Internal.RecordStart), ADR(UIConnect.Output.RangeStart), ADR(UIConnect.Output.RangeEnd), Internal.State);
				
			// Wait for core task to call update command
			IF exLink.RefreshShiftUI AND exLink.RecordCount > 0 THEN			
				Internal.State := exASSETINT_STATE_UI_BUFFER;					
			END_IF
			
			// -------------------------------------------------------------------------------------------
			// Copy shift data from global buffer to shift buffer
		exASSETINT_STATE_UI_BUFFER:
			// Set status
			CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('refresh shift data'), Logger);
			UIConnect.Status := exASSETINT_UI_STATUS_UPDATE;

			// Generate shift data
			Internal.RecordCount := exAssetIntBufferUI(exLink.MemoryShift, exLink, UISetup.SortingStartTime, UIConnect.Filter, RecordTypeShift);
			
			Internal.State := exASSETINT_STATE_UI_DATA;	

			// -------------------------------------------------------------------------------------------
			// Transfer data from buffer to list array
		exASSETINT_STATE_UI_DATA:	
						
			Internal.x := 0;
			brsmemset(ADR(UIConnect.Output), 0, SIZEOF(UIConnect.Output));
			REPEAT
				brsmemcpy(ADR(Internal.RecordData), exLink.MemoryShift + (Internal.x + Internal.RecordStart)*SIZEOF(Internal.RecordData), SIZEOF(Internal.RecordData));
				
				UIConnect.Output.StartTime[Internal.x] := Internal.RecordData.TimeStart;
				UIConnect.Output.EndTime[Internal.x] := Internal.RecordData.TimeEnd;
				UIConnect.Output.ShiftName[Internal.x] := Internal.RecordData.ShiftName;
				UIConnect.Output.CurrentUser[Internal.x] := Internal.RecordData.CurrentUser;
				UIConnect.Output.AdditionalData[Internal.x] := Internal.RecordData.AdditionalData;
				UIConnect.Output.TargetPieces[Internal.x] := Internal.RecordData.TargetPieces;
				UIConnect.Output.TotalPieces[Internal.x] := Internal.RecordData.TotalPieces;
				UIConnect.Output.GoodPieces[Internal.x] := Internal.RecordData.GoodPieces;
				UIConnect.Output.RejectPieces[Internal.x] := Internal.RecordData.RejectPieces;
				UIConnect.Output.BadPieceRate[Internal.x] := Internal.RecordData.BadPieceRate;
				UIConnect.Output.TotalTime[Internal.x] := Internal.RecordData.TotalTime;
				UIConnect.Output.ScheduledDowntime[Internal.x] := Internal.RecordData.ScheduledDowntime;
				UIConnect.Output.UnscheduledDowntime[Internal.x] := Internal.RecordData.UnscheduledDowntime;
				UIConnect.Output.Uptime[Internal.x] := Internal.RecordData.Uptime;
				UIConnect.Output.GoodProductionTime[Internal.x] := Internal.RecordData.GoodProductionTime;
				UIConnect.Output.NominalProductionTime[Internal.x] := Internal.RecordData.NominalProductionTime;
				UIConnect.Output.NominalProductionRate[Internal.x] := Internal.RecordData.NominalProductionTimeRate;
				UIConnect.Output.UnscheduledDowntimeRate[Internal.x] := Internal.RecordData.UnscheduledDowntimeRate;
				UIConnect.Output.ProductionRate[Internal.x] := Internal.RecordData.CurrentProductionRate;
				UIConnect.Output.JobName[Internal.x] := Internal.RecordData.JobName;

				Internal.x := Internal.x + 1;
				
				UNTIL (Internal.x > UI_SHIFT_LIST_IDX) OR (Internal.x + Internal.RecordStart >= Internal.RecordCount)
			END_REPEAT;
											
			exLink.RefreshShiftUI := FALSE;
			
			CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('refresh shift done'), Logger);
			Internal.State := exASSETINT_STATE_IDLE;	
			
			// -------------------------------------------------------------------------------------------
			// Error state
		exASSETINT_STATE_ERROR:		
			IF EDGEPOS(ErrorReset) THEN
				Internal.StateError := exASSETINT_STATE_NONE;
				Internal.State := exASSETINT_STATE_INIT_1;
			END_IF
	END_CASE;
END_FUNCTION_BLOCK

// -------------------------------------------------------------------------------------------
// Shift timeline function block
FUNCTION_BLOCK exAssetIntTimelineUI
	// -------------------------------------------------------------------------------------------
	// Reset everything when enable is false
	IF NOT Enable THEN
		IF ADR(UIConnect) <> 0 THEN
			UIConnect.Filter.Dialog.LayerStatus := UI_LAYER_HIDE;
		END_IF
		StatusID := ERR_FUB_ENABLE_FALSE;
		Active := FALSE;
		Internal.State := exASSETINT_STATE_INIT_1;
		CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('function block disabled'), Logger);
		RETURN;
	END_IF
	
	CASE Internal.State OF

		// -------------------------------------------------------------------------------------------
		// Wait for enable
		exASSETINT_STATE_INIT_1:
			IF Enable THEN
				CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('function block enabled'), Logger);

				// Check prerequisites, exLink and buffers
				IF NOT exAssetIntCheckPreq(exLink, ADR(UIConnect), Logger, ADR(Internal.State), ADR(StatusID), ADR(Info.Diag.StatusID)) THEN
					RETURN;
				END_IF

				// Reset error and status
				Error := FALSE;
				StatusID := ERR_OK;
				Internal.SortingStartTimeOld := exASSETINT_SORTING_ASC;
				
				// Reset filter settings
				exAssetIntFilterReset(ADR(UIConnect.Filter));		

				Internal.State := exASSETINT_STATE_IDLE;
			END_IF

			// -------------------------------------------------------------------------------------------
			// Wait for new event
		exASSETINT_STATE_IDLE:	
			// Set status
			UIConnect.Status := exASSETINT_UI_STATUS_IDLE;
			Active := TRUE;

			// Handle dialog window
			Internal.State := exAssetIntFilterListUI(ADR(UIConnect.Filter), ADR(UIConnect.Status), Logger, Internal.State);
			
			// Handle sorting direction change
			IF UISetup.SortingStartTime <> Internal.SortingStartTimeOld AND exLink.RecordCount > 0 THEN
				Internal.State := exASSETINT_STATE_UI_BUFFER;
			END_IF
			Internal.SortingStartTimeOld := UISetup.SortingStartTime;
			
			// Handle page up and down
			Internal.State := exAssetIntScrollListUI(Internal.RecordCount, UI_TIMELINE_IDX + 1, ADR(UIConnect.Output.PageUp), ADR(UIConnect.Output.PageDown), ADR(UIConnect.Output.StepUp), ADR(UIConnect.Output.StepDown), ADR(Internal.RecordStart), ADR(UIConnect.Output.RangeStart), ADR(UIConnect.Output.RangeEnd), Internal.State);
				
			// Wait for core task to call update command
			IF exLink.RefreshTimelineUI AND exLink.RecordCount > 0 THEN			
				Internal.State := exASSETINT_STATE_UI_BUFFER;					
			END_IF
			
			// -------------------------------------------------------------------------------------------
			// Copy timeline data from global buffer to timeline buffer
		exASSETINT_STATE_UI_BUFFER:
			// Set status
			CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('refresh timeline data'), Logger);
			UIConnect.Status := exASSETINT_UI_STATUS_UPDATE;

			// Generate timeline data
			Internal.RecordCount := exAssetIntBufferUI(exLink.MemoryTimeline, exLink, UISetup.SortingStartTime, UIConnect.Filter, RecordTypeTimeline);
			
			// Generate bar graph data
			Internal.TimeLongest := 0;
			FOR Internal.x := 0 TO Internal.RecordCount DO
				brsmemcpy(ADR(Internal.RecordData), exLink.MemoryTimeline + (Internal.x + Internal.RecordStart)*SIZEOF(Internal.RecordData), SIZEOF(Internal.RecordData));
				
				Internal.TimeSeconds := Internal.RecordData.TotalTime.Hours*60*60 + Internal.RecordData.TotalTime.Minutes*60 + Internal.RecordData.TotalTime.Seconds;
				
				IF Internal.TimeSeconds > Internal.TimeLongest THEN
					Internal.TimeLongest := Internal.TimeSeconds;
				END_IF
			END_FOR
			
			Internal.State := exASSETINT_STATE_UI_DATA;	

			// -------------------------------------------------------------------------------------------
			// Transfer data from buffer to list array
		exASSETINT_STATE_UI_DATA:	
						
			Internal.x := 0;
			brsmemset(ADR(UIConnect.Output), 0, SIZEOF(UIConnect.Output));
			IF Internal.RecordCount > 0 THEN
				REPEAT
					brsmemcpy(ADR(Internal.RecordData), exLink.MemoryTimeline + (Internal.x + Internal.RecordStart)*SIZEOF(Internal.RecordData), SIZEOF(Internal.RecordData));
					Internal.TimeSeconds := Internal.RecordData.TotalTime.Hours*60*60 + Internal.RecordData.TotalTime.Minutes*60 + Internal.RecordData.TotalTime.Seconds;
					
					UIConnect.Output.StartTime[Internal.x] := Internal.RecordData.TimeStart;
					UIConnect.Output.ShiftName[Internal.x] := Internal.RecordData.ShiftName;
					UIConnect.Output.JobName[Internal.x] := Internal.RecordData.JobName;
					UIConnect.Output.ProductionState[Internal.x] := UDINT_TO_UINT(Internal.RecordData.EventType) - 2;
					UIConnect.Output.Duration[Internal.x] := Internal.RecordData.TotalTime;
					UIConnect.Output.Reason[Internal.x] := Internal.RecordData.AdditionalData;
					IF Internal.TimeLongest > 0 THEN
						UIConnect.Output.DurationBar[Internal.x].Duration := REAL_TO_UDINT(UDINT_TO_REAL(Internal.TimeSeconds)/UDINT_TO_REAL(Internal.TimeLongest)*100);
					END_IF
					
					IF Internal.RecordData.EventType = RecordTypeUptime THEN
						UIConnect.Output.DurationBar[Internal.x].Color := 2;
					ELSIF Internal.RecordData.EventType = RecordTypeDowntimeScheduled THEN
						UIConnect.Output.DurationBar[Internal.x].Color := 14;
					ELSIF Internal.RecordData.EventType = RecordTypeDowntimeUnscheduled THEN
						UIConnect.Output.DurationBar[Internal.x].Color := 51;
					END_IF
	
					Internal.x := Internal.x + 1;
					
					UNTIL (Internal.x > UI_TIMELINE_IDX) OR (Internal.x + Internal.RecordStart >= Internal.RecordCount)
				END_REPEAT;
			END_IF
			
			exLink.RefreshTimelineUI := FALSE;
			
			CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('refresh timeline done'), Logger);
			Internal.State := exASSETINT_STATE_IDLE;	
			
			// -------------------------------------------------------------------------------------------
			// Error state
		exASSETINT_STATE_ERROR:		
			IF EDGEPOS(ErrorReset) THEN
				Internal.StateError := exASSETINT_STATE_NONE;
				Internal.State := exASSETINT_STATE_INIT_1;
			END_IF
	END_CASE;
END_FUNCTION_BLOCK

// -------------------------------------------------------------------------------------------
// Generate buffer data for job, shift or timeline
FUNCTION exAssetIntBufferUI
	// Set up start values, function locals are not initialized
	RecordCount := 0;
	y := 0;

	brsmemset(Memory, 0, CORE_EVENT_NUM_MAX*SIZEOF(RecordData));
	IF exLink.RecordCount > 0 THEN
		REPEAT
			// Check sorting direction
			IF SortingStartTime = exASSETINT_SORTING_ASC THEN
				brsmemcpy(ADR(RecordData), exLink.MemoryDb + (exLink.RecordCount - y - 1)*SIZEOF(RecordData), SIZEOF(RecordData));
			ELSE
				brsmemcpy(ADR(RecordData), exLink.MemoryDb + y*SIZEOF(RecordData), SIZEOF(RecordData));
			END_IF
					
			// Data must match event type
			// or eventy type is shift and data is shift or job and flag is set to show job and shift data together
			// or eventy type is timeline and data timeline data (>= RecordTypeNoShift)
			IF (RecordData.EventType = EventType) OR 
			   (EventType = RecordTypeShift AND UI_SHIFT_SHOW_JOBS AND (RecordData.EventType = RecordTypeShift OR RecordData.EventType = RecordTypeJob)) OR 
     		   (EventType = RecordTypeTimeline AND RecordData.EventType >= RecordTypeNoShift) THEN
				// Only transfer data that matches filter
				IF (NOT Filter.Current.From.Enable AND NOT Filter.Current.Until.Enable) OR 
					(Filter.Current.From.Enable AND Filter.Current.From.DateTime <= RecordData.TimeStart AND NOT Filter.Current.Until.Enable) OR 	
					(NOT Filter.Current.From.Enable AND Filter.Current.Until.Enable AND Filter.Current.Until.DateTime >= RecordData.TimeEnd) OR 	
					(Filter.Current.From.Enable AND Filter.Current.From.DateTime <= RecordData.TimeStart AND Filter.Current.Until.Enable AND Filter.Current.Until.DateTime >= RecordData.TimeEnd) THEN	
							
					brsmemcpy(Memory + RecordCount*SIZEOF(RecordData), ADR(RecordData), SIZEOF(RecordData));
					RecordCount := RecordCount + 1;
				END_IF
			END_IF
		  
			y := y + 1;
						
			UNTIL (y = exLink.RecordCount)
		END_REPEAT;
	END_IF
	
	exAssetIntBufferUI := RecordCount;
END_FUNCTION

// -------------------------------------------------------------------------------------------
// Check prerequisites, exLink and buffers
FUNCTION exAssetIntCheckPreq
	// Make sure we have remanent buffer
	IF ADR(exLink) = 0 THEN
		// Set status, remember state, go to error state
		StatusID := CreateErrorState(ERR_ASSET_LINK, ADR('ERR: exLink is 0'), Logger, exCOM_SEV_ERROR,  ADR(State), ADR(InfoDiagStatusID));
		exAssetIntCheckPreq := FALSE;
		RETURN;				
	END_IF
	// Make sure we have UIConnect
	IF UIConnect = 0 THEN
		// Set status, remember state, go to error state
		StatusID := CreateErrorState(ERR_ASSET_LINK, ADR('ERR: UIConnect is 0'), Logger, exCOM_SEV_ERROR,  ADR(State), ADR(InfoDiagStatusID));
		exAssetIntCheckPreq := FALSE;
		RETURN;				
	END_IF
	// Make sure we have temporary buffer
	IF exLink.MemoryDb = 0 OR exLink.MemoryJob = 0 OR exLink.MemoryTimeline = 0 THEN
		// Set status, remember state, go to error state
		StatusID := CreateErrorState(ERR_ASSET_TEMP_MEMORY, ADR('ERR: no temp memory'), Logger, exCOM_SEV_ERROR,  ADR(State), ADR(InfoDiagStatusID));
		exAssetIntCheckPreq := FALSE;
		RETURN;				
	END_IF
	// Make sure core function block is active
	IF NOT exLink.IsCoreActive THEN
		// Set status, remember state, go to error state
		StatusID := CreateErrorState(exASSETINT_INF_WAIT_CORE_FB, ADR('ERR: core is not active'), Logger, exCOM_SEV_ERROR,  ADR(State), ADR(InfoDiagStatusID));
		exAssetIntCheckPreq := FALSE;
		RETURN;				
	END_IF
	exAssetIntCheckPreq := TRUE;
END_FUNCTION

// -------------------------------------------------------------------------------------------
// Handle list scrolling
FUNCTION exAssetIntScrollListUI
	exAssetIntScrollListUI := State;
	
	// Nothing to do
	IF RecordCount = 0 THEN
		RETURN;
	END_IF
	
	// -------------------------------------------------------------------------------------------
	// Handle page up and down
	IF PageUp THEN
		RecordStart := RecordStart - ListMaxCount;
		exAssetIntScrollListUI := exASSETINT_STATE_UI_DATA;					
	END_IF
	IF PageDown THEN
		RecordStart := RecordStart + ListMaxCount;					
		exAssetIntScrollListUI := exASSETINT_STATE_UI_DATA;					
	END_IF
				
	// -------------------------------------------------------------------------------------------
	// Handle step up and down
	IF StepUp THEN
		RecordStart := RecordStart - 1;
		exAssetIntScrollListUI := exASSETINT_STATE_UI_DATA;					
	END_IF
	IF StepDown THEN
		RecordStart := RecordStart + 1;					
		exAssetIntScrollListUI := exASSETINT_STATE_UI_DATA;					
	END_IF
				
	// -------------------------------------------------------------------------------------------
	// Correction for step/page up/down
	IF RecordStart + ListMaxCount > UDINT_TO_DINT(RecordCount) THEN
		RecordStart := RecordCount - ListMaxCount;
	END_IF
	IF RecordStart < 0 THEN
		RecordStart := 0;
	END_IF
	
	// -------------------------------------------------------------------------------------------
	// Calculate range start
	IF UINT_TO_REAL(UI_TIMELINE_IDX + 1) / UINT_TO_REAL(RecordCount) < 1 THEN
		RangeStart := 100 - (DINT_TO_REAL(RecordStart) / UINT_TO_REAL(RecordCount)) * 100.0;
		RangeEnd := RangeStart - (UINT_TO_REAL(UI_TIMELINE_IDX + 1) / UINT_TO_REAL(RecordCount)) * 100.0; 
	ELSE
		RangeStart := 0;
		RangeEnd := 100;
	END_IF
	
	PageUp := FALSE;
	PageDown := FALSE;
	StepUp := FALSE;
	StepDown := FALSE;
	
END_FUNCTION

// -------------------------------------------------------------------------------------------
// Reset filter settings
FUNCTION exAssetIntFilterReset
	Filter.DefaultLayerStatus := 0;
	Filter.Dialog.LayerStatus := 1;
	Filter.Dialog.From.Year := 1970;
	Filter.Dialog.From.Month := 1;
	Filter.Dialog.From.Day := 1;
	Filter.Dialog.Until.Year := 1970;
	Filter.Dialog.Until.Month := 1;
	Filter.Dialog.Until.Day := 1;
	
	exAssetIntFilterReset := TRUE;
END_FUNCTION
	
// -------------------------------------------------------------------------------------------
// Handle dialog window
FUNCTION exAssetIntFilterListUI
	// Open dialog window
	IF Filter.ShowDialog THEN
		CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('show dialog window'), Logger);
		
		Filter.Dialog.LayerStatus := UI_LAYER_SHOW;
		Filter.DefaultLayerStatus := UI_LAYER_LOCK;
		Filter.ShowDialog := FALSE;
	END_IF
	
	// Dialog is open
	IF Filter.Dialog.LayerStatus = 0 THEN
		Status := exASSETINT_UI_STATUS_FILTER;
		
		// Button cancel
		IF Filter.Dialog.Cancel THEN
			CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('dialog canceled'), Logger);

			Filter.Dialog.LayerStatus := UI_LAYER_HIDE;
			Filter.DefaultLayerStatus := UI_LAYER_SHOW;
			Filter.Dialog.Cancel := 0;
		END_IF
		// Button ok
		IF Filter.Dialog.Confirm THEN
			CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('dialog ok'), Logger);

			DT_TO_DTStructure_0.year := Filter.Dialog.From.Year;
			DT_TO_DTStructure_0.month := Filter.Dialog.From.Month;
			DT_TO_DTStructure_0.day := Filter.Dialog.From.Day;
			DT_TO_DTStructure_0.hour := Filter.Dialog.From.Hour;
			DT_TO_DTStructure_0.minute := Filter.Dialog.From.Minute;
			Filter.Current.From.DateTime := DTStructure_TO_DT(ADR(DT_TO_DTStructure_0));
			Filter.Current.From.Enable := Filter.Dialog.From.Enable;
	
			DT_TO_DTStructure_0.year := Filter.Dialog.Until.Year;
			DT_TO_DTStructure_0.month := Filter.Dialog.Until.Month;
			DT_TO_DTStructure_0.day := Filter.Dialog.Until.Day;
			DT_TO_DTStructure_0.hour := Filter.Dialog.Until.Hour;
			DT_TO_DTStructure_0.minute := Filter.Dialog.Until.Minute;
			Filter.Current.Until.DateTime := DTStructure_TO_DT(ADR(DT_TO_DTStructure_0));
			Filter.Current.Until.Enable := Filter.Dialog.Until.Enable;
	
			Filter.Dialog.LayerStatus := UI_LAYER_HIDE;
			Filter.DefaultLayerStatus := UI_LAYER_SHOW;
			Filter.Dialog.Confirm := 0;
						
			exAssetIntFilterListUI := exASSETINT_STATE_UI_BUFFER;
			RETURN;
		END_IF
	END_IF
	exAssetIntFilterListUI := State;

END_FUNCTION
