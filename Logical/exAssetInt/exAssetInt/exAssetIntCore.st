// -------------------------------------------------------------------------------------------
// File version 1012
// -------------------------------------------------------------------------------------------
// Core function block
FUNCTION_BLOCK exAssetIntCore
	// -------------------------------------------------------------------------------------------
	// Reset everything when enable is false
	IF NOT Enable THEN
		Active := FALSE;
		exLink.IsCoreActive := FALSE;
		StatusID := ERR_FUB_ENABLE_FALSE;
		Internal.State := exASSETINT_STATE_INIT_1;
		CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('function block disabled'), Logger);
		RETURN;
	END_IF
	
	// Permanent watch critical values
	IF Internal.State <> exASSETINT_STATE_ERROR THEN
		// Make sure we have remanent buffer
		IF ADR(exLink) = 0 THEN
			// Set status, remember state, go to error state
			StatusID := CreateErrorState(ERR_ASSET_LINK, ADR('ERR: exLink is 0'), Logger, exCOM_SEV_ERROR, ADR(Internal.State), ADR(Info.Diag.StatusID));
			RETURN;			
		END_IF
		// Make sure we have valid memory data
		IF (exLink.MemoryDb = 0 OR exLink.MemoryJob = 0 OR exLink.MemoryShift = 0 OR exLink.MemoryTimeline = 0) AND Active THEN			
			// Set status, remember state, go to error state
			StatusID := CreateErrorState(ERR_ASSET_LINK, ADR('ERR: memory address is 0'), Logger, exCOM_SEV_ERROR, ADR(Internal.State), ADR(Info.Diag.StatusID));
			RETURN;			
		END_IF
		// Make sure we have a configuration
		IF ADR(Configuration) = 0 THEN
			// Set status, remember state, go to error state
			StatusID := CreateErrorState(ERR_ASSET_LINK, ADR('ERR: No configuation attached'), Logger, exCOM_SEV_ERROR, ADR(Internal.State), ADR(Info.Diag.StatusID));
			RETURN;			
		END_IF
		// Make sure we have a parameters
		IF ADR(Parameters) = 0 THEN
			// Set status, remember state, go to error state
			StatusID := CreateErrorState(ERR_ASSET_LINK, ADR('ERR: No parameters attached'), Logger, exCOM_SEV_ERROR, ADR(Internal.State), ADR(Info.Diag.StatusID));
			RETURN;			
		END_IF
		// Make sure we have a device name
		IF ADR(DeviceName) = 0 THEN
			// Set status, remember state, go to error state
			StatusID := CreateErrorState(ERR_ASSET_LINK, ADR('ERR: No device name attached'), Logger, exCOM_SEV_ERROR, ADR(Internal.State), ADR(Info.Diag.StatusID));
			RETURN;			
		END_IF
		// Make sure we have a storage name
		IF ADR(StorageName) = 0 THEN
			// Set status, remember state, go to error state
			StatusID := CreateErrorState(ERR_ASSET_LINK, ADR('ERR: No storage name attached'), Logger, exCOM_SEV_ERROR, ADR(Internal.State), ADR(Info.Diag.StatusID));
			RETURN;			
		END_IF
	END_IF
	
	CASE Internal.State OF

		// -------------------------------------------------------------------------------------------
		// Wait for enable
		// -------------------------------------------------------------------------------------------
		exASSETINT_STATE_INIT_1:
			IF Enable THEN
				CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('function block enabled'), Logger);
							
				exLink.RecordCount := 0;
				exLink.Version := EXLINK_VERSION;

				// -------------------------------------------------------------------------------------------
				// Reset error, status and function and internal blocks
				brsmemset(ADR(Info.Diag), 0, SIZEOF(Info.Diag));
				Error := FALSE;
				StatusID := ERR_OK;
				Internal.CreateMemory(Enable := FALSE);
				Internal.ReadEventData(Enable := FALSE);
				Internal.WriteEventData(Enable := FALSE);
				Internal.ReadEventData(Enable := FALSE);
				Internal.WriteEventData(Enable := FALSE);
				Internal.DirCreate_0.enable := FALSE;
				Internal.DirCreate_0();
				
				// Update time information
				Internal.CurrentTime(enable := TRUE);
				IF exLink.StatsLastCall.year > 0 THEN
					// Make sure we power back on in the future
					IF DiffDT(Internal.CurrentTime.DT1, DTStructure_TO_DT(ADR(exLink.StatsLastCall))) <> 16#FFFFFFFF THEN
						Internal.PowerOffTime := DTStructure_TO_DT(ADR(exLink.StatsLastCall));
					END_IF
				END_IF
				
				// -------------------------------------------------------------------------------------------
				// Create folder structure and read event data only after boot
				IF Internal.InitAfterBoot THEN
					Internal.State := exASSETINT_STATE_INIT_4;
				ELSE
					// -------------------------------------------------------------------------------------------
					// Try to restore backup when link data is empty
					IF exLink.MemoryDb = 0 THEN
						Internal.State := exASSETINT_STATE_LOAD_LINK;
					ELSE
						Internal.State := exASSETINT_STATE_INIT_2;
					END_IF
				END_IF
			END_IF

			// -------------------------------------------------------------------------------------------
			// Create folder structure
			// -------------------------------------------------------------------------------------------
		exASSETINT_STATE_INIT_2:
			Internal.DirCreate_0.enable := TRUE;
			Internal.DirCreate_0.pDevice := ADR(StorageName);
			Internal.DirCreate_0.pName := ADR(CORE_FOLDER_NAME);
			Internal.DirCreate_0();
					
			// -------------------------------------------------------------------------------------------
			// Folder structure successful created
			IF Internal.DirCreate_0.status = ERR_OK OR Internal.DirCreate_0.status = fiERR_DIR_ALREADY_EXIST THEN
				CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('create folder structure ok'), Logger);
				Internal.State := exASSETINT_STATE_INIT_3;
			
				// Error
			ELSIF Internal.DirCreate_0.status <> ERR_FUB_BUSY THEN
				// Set status, remember state, go to error state
				StatusID := CreateErrorState(Internal.DirCreate_0.status, ADR('ERR: create folder structure'), Logger, exCOM_SEV_ERROR, ADR(Internal.State), ADR(Info.Diag.StatusID));
			END_IF
			
			// -------------------------------------------------------------------------------------------
			// Create internal memory
			// -------------------------------------------------------------------------------------------
		exASSETINT_STATE_INIT_3:
			Internal.CreateMemory.Enable := TRUE;
			Internal.CreateMemory.Size := CORE_EVENT_NUM_MAX*SIZEOF(Internal.RecordData);
			Internal.CreateMemory.Logger := Logger;
			Internal.CreateMemory();
			
			// -------------------------------------------------------------------------------------------
			// Memory structure successful created
			IF Internal.CreateMemory.Status = ERR_OK THEN
				CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('create internal memory ok'), Logger);
				exLink.MemoryDb := Internal.CreateMemory.MemoryDb;
				exLink.MemoryJob := Internal.CreateMemory.MemoryJob; 
				exLink.MemoryShift := Internal.CreateMemory.MemoryShift;
				exLink.MemoryTimeline := Internal.CreateMemory.MemoryTimeline;
				Internal.InitAfterBoot := TRUE;
				Internal.State := exASSETINT_STATE_INIT_4;
			
				// Error
			ELSIF Internal.CreateMemory.Status <> ERR_FUB_BUSY THEN
				// Set status, remember state, go to error state
				StatusID := CreateErrorState(Internal.CreateMemory.Status, ADR('ERR: create internal memory'), Logger, exCOM_SEV_ERROR, ADR(Internal.State), ADR(Info.Diag.StatusID));
			END_IF
			
			// -------------------------------------------------------------------------------------------
			// Read event data
			// -------------------------------------------------------------------------------------------
		exASSETINT_STATE_INIT_4:
			Internal.ReadEventData.Enable := TRUE;
			Internal.ReadEventData.Device := StorageName;
			Internal.ReadEventData.Memory := exLink.MemoryDb;
			Internal.ReadEventData.RecordIndexUsed := ADR(Internal.RecordIndexUsed);
			Internal.ReadEventData.Logger := Logger;
			Internal.ReadEventData();
		
			// Read events successful
			IF Internal.ReadEventData.Status = ERR_OK THEN
				CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('read stored events ok'), Logger);
				
				// -------------------------------------------------------------------------------------------
				// Get record count, calculate next entry
				exLink.RecordCount := Internal.ReadEventData.RecordCount;				
				Internal.State := exASSETINT_STATE_INIT_5;
				
				// Error
			ELSIF Internal.ReadEventData.Status <> ERR_FUB_BUSY THEN
				// Set status, remember state, go to error state
				StatusID := CreateErrorState(Internal.ReadEventData.Status, ADR('ERR: read stored events'), Logger, exCOM_SEV_ERROR, ADR(Internal.State), ADR(Info.Diag.StatusID));
			END_IF

			// -------------------------------------------------------------------------------------------
			// Set inital values
			// -------------------------------------------------------------------------------------------
		exASSETINT_STATE_INIT_5:
			// -------------------------------------------------------------------------------------------
			// Transfer start values
			exLink.JobStatistics.JobName := Parameters.Job;
			exLink.JobStatistics.CurrentUser := Parameters.CurrentUser;
			exLink.JobStatistics.AdditionalData := Parameters.AdditionalData;
			Internal.JobPieceCounterOld := PieceCounter;
			Internal.JobRejectCounterOld := RejectCounter;

			exLink.ShiftStatistics.CurrentUser := Parameters.CurrentUser;
			exLink.ShiftStatistics.AdditionalData := Parameters.AdditionalData;
			Internal.ShiftPieceCounterOld := PieceCounter;
			Internal.ShiftRejectCounterOld := RejectCounter;
				
			// -------------------------------------------------------------------------------------------
			// Check shift configuration for errors
			IF NOT exAssetIntCheckShiftData(Configuration, Logger, ADR(Internal.State), ADR(StatusID), ADR(Info.Diag.StatusID)) THEN
				RETURN;
			END_IF

			// Transfer configuration
			brsmemcpy(ADR(exLink.Configuration), ADR(Configuration), SIZEOF(Configuration));
			
			// -------------------------------------------------------------------------------------------
			// Remember start called time
			Internal.TimeLastCallShift := clock_ms();
			Internal.TimeLastCallProduction := clock_ms();
				
			// -------------------------------------------------------------------------------------------
			// Refresh UI data, finish up
			exLink.RefreshJobUI := TRUE;
			exLink.RefreshShiftUI := TRUE;
			exLink.RefreshTimelineUI := TRUE;
			Internal.State := exASSETINT_STATE_IDLE;
			
			// -------------------------------------------------------------------------------------------
			// Wait for new event
			// -------------------------------------------------------------------------------------------
		exASSETINT_STATE_IDLE:
			// Set core active, reset read write function blocks
			Active := TRUE;
			exLink.IsCoreActive := TRUE;
			Internal.ReadEventData(Enable := FALSE);
			Internal.WriteEventData(Enable := FALSE);
			
			// Update time information
			Internal.CurrentTime(enable := TRUE);
			DT_TO_DTStructure(Internal.CurrentTime.DT1, ADR(exLink.StatsLastCall));          
			Internal.TimeOfDay := UDINT_TO_TOD((USINT_TO_UDINT(exLink.StatsLastCall.hour) * 3600000) + (USINT_TO_UDINT(exLink.StatsLastCall.minute) * 60000) + (USINT_TO_UDINT(exLink.StatsLastCall.second) * 1000));

			// Set stats timer
			Internal.StatsRefresh.IN := TRUE;
			Internal.StatsRefresh.PT := exLink.Configuration.CalculationTimeBase/10;	
			Internal.StatsRefresh();

			// Internal data backup timer
			Internal.BackupTimer.IN := TRUE;
			Internal.BackupTimer.PT := CORE_BACKUP_TIMER*60*100;	
			Internal.BackupTimer();
			IF Internal.BackupTimer.Q THEN
				Internal.BackupTimer.IN := FALSE;
				Internal.BackupTimer();

				Internal.State := exASSETINT_STATE_SAVE_LINK;
				RETURN;
			END_IF

			// Transfer downtime information
			Internal.Downtime := Downtime;
			IF ADR(DowntimeReason) <> 0 THEN
				Internal.DowntimeReason := DowntimeReason;
			ELSE
				Internal.DowntimeReason := '';
			END_IF

			// -------------------------------------------------------------------------------------------			
			// Handle shift state change
			IF TrackShiftChange(ADR(exLink), ADR(Internal), ADR(Info), Parameters, Logger) THEN
				RETURN;
			END_IF
			
			// -------------------------------------------------------------------------------------------
			// Calculate shift and job statistics
			IF Internal.ShiftName <> '' THEN
			
				// Calculate new stats
				IF Internal.StatsRefresh.Q THEN
					// Get time difference between calls
					Internal.DiffLastCallShift := DiffT(clock_ms(), Internal.TimeLastCallShift);
					Internal.TimeLastCallShift := clock_ms();
					
					// Handle diff timer overflow
					IF Internal.DiffLastCallShift = 16#FFFFFFFF THEN
						CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('diff timer overflow'), Logger);
					ELSE
					
						// Do not count when downtime is active
						IF Internal.Downtime = exASSETINT_NO_DOWNTIME THEN
							// Transfer job counter data
							IF Internal.JobPieceCounterOld <= PieceCounter THEN					
								exLink.JobStatistics.TotalPieces := exLink.JobStatistics.TotalPieces + (PieceCounter - Internal.JobPieceCounterOld);
							ELSE
								CreateLoggerEntry(exASSETINT_LOG_ERROR, ADR('job piece count overflow'), Logger);
								exLink.JobStatistics.TotalPieces := exLink.JobStatistics.TotalPieces + (16#FFFFFFFF - Internal.JobPieceCounterOld + PieceCounter);
							END_IF
							
							IF Internal.JobRejectCounterOld <= RejectCounter THEN					
								exLink.JobStatistics.RejectPieces := exLink.JobStatistics.RejectPieces + (RejectCounter - Internal.JobRejectCounterOld);
							ELSE
								CreateLoggerEntry(exASSETINT_LOG_ERROR, ADR('job reject count overflow'), Logger);
								exLink.JobStatistics.RejectPieces := exLink.JobStatistics.RejectPieces + (16#FFFFFFFF - Internal.JobRejectCounterOld + RejectCounter);
							END_IF
						END_IF
						Internal.JobPieceCounterOld := PieceCounter;
						Internal.JobRejectCounterOld := RejectCounter;
						CalcStatsJob(exLink, Internal.DiffLastCallShift, Internal.Downtime, Parameters, ADR(Info.JobStatistics));
						
						// Do not count when downtime is active
						IF Internal.Downtime = exASSETINT_NO_DOWNTIME THEN
							// Transfer shift counter data
							IF Internal.ShiftPieceCounterOld <= PieceCounter THEN					
								exLink.ShiftStatistics.TotalPieces := exLink.ShiftStatistics.TotalPieces + (PieceCounter - Internal.ShiftPieceCounterOld);
							ELSE
								CreateLoggerEntry(exASSETINT_LOG_ERROR, ADR('shift piece count overflow'), Logger);
								exLink.ShiftStatistics.TotalPieces := exLink.ShiftStatistics.TotalPieces + (16#FFFFFFFF - Internal.ShiftPieceCounterOld + PieceCounter);
							END_IF
							
							IF Internal.ShiftRejectCounterOld <= RejectCounter THEN					
								exLink.ShiftStatistics.RejectPieces := exLink.ShiftStatistics.RejectPieces + (RejectCounter - Internal.ShiftRejectCounterOld);
							ELSE
								CreateLoggerEntry(exASSETINT_LOG_ERROR, ADR('shift reject count overflow'), Logger);
								exLink.ShiftStatistics.RejectPieces := exLink.ShiftStatistics.RejectPieces + (16#FFFFFFFF - Internal.ShiftRejectCounterOld + RejectCounter);
							END_IF
						END_IF
						Internal.ShiftPieceCounterOld := PieceCounter;
						Internal.ShiftRejectCounterOld := RejectCounter;
						CalcStatsShift(exLink, Internal.DiffLastCallShift, Internal.Downtime, Parameters, ADR(Info.ShiftStatistics));
						
						// Transfer shift data to main function block
						CurrentProductionRate := exLink.ShiftStatistics.CurrentProductionRate;
						NominalProductionTimeRate := exLink.ShiftStatistics.NominalProductionTimeRate;
						BadPieceRate := exLink.ShiftStatistics.BadPieceRate;
						ScheduledDowntimeRate := exLink.ShiftStatistics.ScheduledDowntimeRate;
						UnscheduledDowntimeRate := exLink.ShiftStatistics.UnscheduledDowntimeRate;
						
					END_IF			
				END_IF
				
				// When no shift is active
			ELSE
				// Dont count when no shift is active, reset last call
				Internal.ShiftPieceCounterOld := PieceCounter;
				Internal.ShiftRejectCounterOld := RejectCounter;
				Internal.JobPieceCounterOld := PieceCounter;
				Internal.JobRejectCounterOld := RejectCounter;

				Internal.TimeLastCallShift := clock_ms();
			END_IF
					
			// -------------------------------------------------------------------------------------------			
			// Handle production state change
			IF TrackProductionState(ADR(exLink), ADR(Internal), Parameters, Logger) THEN
				RETURN;
			END_IF
			
			// -------------------------------------------------------------------------------------------
			// Handle update command
			IF EDGEPOS(Update) THEN
				CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('update command triggered'), Logger);

				// -------------------------------------------------------------------------------------------
				// Check shift configuration for errors
				IF NOT exAssetIntCheckShiftData(Configuration, Logger, ADR(Internal.State), ADR(StatusID), ADR(Info.Diag.StatusID)) THEN
					RETURN;
				END_IF
								
				// Transfer configuration
				brsmemcpy(ADR(exLink.Configuration), ADR(Configuration), SIZEOF(Configuration));				

				// Job has changed
				IF Parameters.Job <> exLink.JobStatistics.JobName THEN
					Internal.TmpStr1 := 'new job started ';
					brsstrcat(ADR(Internal.TmpStr1), ADR(Parameters.Job));
					CreateLoggerEntry(exASSETINT_LOG_INFO, ADR(Internal.TmpStr1), Logger);

					CommandBusy := TRUE;
					CommandDone := FALSE;
					UpdateDone := FALSE;

					// Transfer stats to record, make sure structures are allignent
					brsmemset(ADR(Internal.RecordData), 0, SIZEOF(Internal.RecordData));
					
					// Collect data for record
					Internal.RecordData.EventType := RecordTypeJob;
					Internal.RecordData.TimeStart := exLink.JobStatistics.StartTime;
					Internal.RecordData.TimeEnd := Internal.CurrentTime.DT1;
					// Take job user is known otherwise use current user from parameter
					IF exLink.JobStatistics.CurrentUser <> '' THEN
						Internal.RecordData.CurrentUser := exLink.JobStatistics.CurrentUser;
					ELSE
						Internal.RecordData.CurrentUser := Parameters.CurrentUser;
					END_IF
					Internal.RecordData.AdditionalData := Parameters.AdditionalData;
					Internal.RecordData.ShiftName := exLink.ShiftStatistics.ShiftName;
					Internal.RecordData.JobName := exLink.JobStatistics.JobName;				
					Internal.RecordData.TotalPieces := exLink.JobStatistics.TotalPieces;
					Internal.RecordData.GoodPieces := exLink.JobStatistics.GoodPieces;
					Internal.RecordData.RejectPieces := exLink.JobStatistics.RejectPieces;
					Internal.RecordData.BadPieceRate := exLink.JobStatistics.BadPieceRate;
					Internal.RecordData.TotalTime := exLink.JobStatistics.TotalTime;
					Internal.RecordData.ScheduledDowntime := exLink.JobStatistics.ScheduledDowntime;
					Internal.RecordData.UnscheduledDowntime := exLink.JobStatistics.UnscheduledDowntime;
					Internal.RecordData.Uptime := exLink.JobStatistics.Uptime;
					Internal.RecordData.GoodProductionTime := exLink.JobStatistics.GoodProductionTime;
					Internal.RecordData.NominalProductionTime := exLink.JobStatistics.NominalProductionTime;
					Internal.RecordData.NominalProductionTimeRate := exLink.JobStatistics.NominalProductionTimeRate;
					Internal.RecordData.UnscheduledDowntimeRate := exLink.JobStatistics.UnscheduledDowntimeRate;
					Internal.RecordData.CurrentProductionRate := exLink.JobStatistics.CurrentProductionRate;								
				
					// Reset stats and remember new start time
					brsmemset(ADR(Info.JobStatistics), 0, SIZEOF(Info.JobStatistics));
					brsmemset(ADR(exLink.JobStatistics), 0, SIZEOF(exLink.JobStatistics));

					exLink.JobTotalTime := 0;
					exLink.JobDowntimeScheduled := 0;
					exLink.JobDowntimeUnscheduled := 0;
					
					// Transfer data to job stats
					exLink.JobStatistics.StartTime := Internal.CurrentTime.DT1;
					exLink.JobStatistics.JobName := Parameters.Job;
					
					Internal.State := exASSETINT_STATE_STORE_EVENT;
				ELSE
					CommandBusy := FALSE;
					CommandDone := TRUE;
					UpdateDone := TRUE;
				END_IF
				
				// Transfer username and additional data
				exLink.JobStatistics.CurrentUser := Parameters.CurrentUser;
				exLink.JobStatistics.AdditionalData := Parameters.AdditionalData;

				exLink.ShiftStatistics.CurrentUser := Parameters.CurrentUser;
				exLink.ShiftStatistics.AdditionalData := Parameters.AdditionalData;
				
			END_IF
			
			IF NOT Update THEN
				UpdateDone := FALSE;
			END_IF
			
			// -------------------------------------------------------------------------------------------
			// Handle reset command
			IF EDGEPOS(Reset) THEN
				CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('reset command triggered'), Logger);

				CommandBusy := TRUE;
				CommandDone := FALSE;
				
				// Reset stats
				brsmemset(ADR(Info.JobStatistics), 0, SIZEOF(Info.JobStatistics));
				brsmemset(ADR(exLink.JobStatistics), 0, SIZEOF(exLink.JobStatistics));

				exLink.JobTotalTime := 0;
				exLink.JobDowntimeScheduled := 0;
				exLink.JobDowntimeUnscheduled := 0;
					
				// Transfer data to job stats
				exLink.JobStatistics.StartTime := Internal.CurrentTime.DT1;
				exLink.JobStatistics.JobName := Parameters.Job;
				exLink.JobStatistics.CurrentUser := Parameters.CurrentUser;
				exLink.JobStatistics.AdditionalData := Parameters.AdditionalData;

				// Reset stats
				brsmemset(ADR(Info.ShiftStatistics), 0, SIZEOF(Info.ShiftStatistics));
				brsmemset(ADR(exLink.ShiftStatistics), 0, SIZEOF(exLink.ShiftStatistics));

				exLink.ShiftTotalTime := 0;
				exLink.ShiftDowntimeScheduled := 0;
				exLink.ShiftDowntimeUnscheduled := 0;

				// Transfer data to shift stats
				exLink.ShiftId := Internal.ShiftId;			
				exLink.ShiftStatistics.StartTime := Internal.CurrentTime.DT1;
				exLink.ShiftStatistics.ShiftName := Internal.ShiftName;
				exLink.ShiftStatistics.CurrentUser := Parameters.CurrentUser;
				exLink.ShiftStatistics.AdditionalData := Parameters.AdditionalData;

				CommandBusy := FALSE;
				CommandDone := TRUE;
			END_IF
					
			// -------------------------------------------------------------------------------------------
			// Handle export command
			IF EDGEPOS(Export) THEN	

				CommandBusy := TRUE;
				CommandDone := FALSE;
				ExportDone := FALSE;
	
				Internal.State := exASSETINT_STATE_EXPORT_EVENTS;
			END_IF
			
			IF NOT Export THEN
				ExportDone := FALSE;
			END_IF
			
			// -------------------------------------------------------------------------------------------
			// Reset refresh timer
			IF Internal.StatsRefresh.Q THEN
				// Set stats timer
				Internal.StatsRefresh.IN := FALSE;
				Internal.StatsRefresh();
			END_IF
			
			IF Update = FALSE AND Export = FALSE AND Reset = FALSE THEN
				CommandDone := FALSE;
			END_IF

			// -------------------------------------------------------------------------------------------
			// Store new event
			// -------------------------------------------------------------------------------------------
		exASSETINT_STATE_STORE_EVENT:
			// Find new record name
			IF exLink.RecordCount < CORE_EVENT_NUM_MAX THEN
				// Make sure record index is not already used
				FOR Internal.x := 0 TO exLink.RecordCount DO
					IF NOT Internal.RecordIndexUsed[Internal.x] THEN
						Internal.RecordIndex := Internal.x;
						EXIT;
					END_IF
				END_FOR;
			ELSE
				// Use last entry record name
				brsmemset(ADR(Internal.TmpStr1), 0, SIZEOF(Internal.TmpStr1));
				brsmemcpy(ADR(Internal.TmpStr1), exLink.MemoryDb + (exLink.RecordCount - 1)*SIZEOF(Internal.RecordData) +  1, SIZEOF(Internal.RecordData.FileName));
				brsstrcpy(ADR(Internal.TmpStr1), ADR(Internal.TmpStr1) + FindInstr(ADR(Internal.TmpStr1), ADR('#')) + 1);
				Internal.RecordIndex := DINT_TO_UINT(brsatoi(ADR(Internal.TmpStr1)));
			END_IF
			
			Internal.WriteEventData.Enable := TRUE;
			Internal.WriteEventData.Device := StorageName;
			Internal.WriteEventData.Logger := Logger;
			Internal.WriteEventData.RecordData := ADR(Internal.RecordData);
			Internal.WriteEventData.RecordIndex := Internal.RecordIndex;
			Internal.WriteEventData();
		
			// -------------------------------------------------------------------------------------------
			// Event successful created
			IF Internal.WriteEventData.Status = ERR_OK THEN
				CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('create new event ok'), Logger);
				
				// Copy new record into memeory
				IF exLink.RecordCount < CORE_EVENT_NUM_MAX THEN
					exLink.RecordCount := exLink.RecordCount + 1;
				END_IF
				brsmemmove(exLink.MemoryDb + SIZEOF(Internal.RecordData), exLink.MemoryDb, SIZEOF(Internal.RecordData)*(exLink.RecordCount - 1));										
				brsmemcpy(exLink.MemoryDb, ADR(Internal.RecordData), SIZEOF(Internal.RecordData));
				Internal.RecordIndexUsed[Internal.RecordIndex] := TRUE;
								
				// Refrehs UI data, finish up
				exLink.RefreshJobUI := TRUE;
				exLink.RefreshShiftUI := TRUE;
				exLink.RefreshTimelineUI := TRUE;

				// Set update done flag
				IF Update AND CommandBusy THEN
					UpdateDone := TRUE;
				END_IF
				CommandBusy := FALSE;
				CommandDone := TRUE;

				StatusID := ERR_OK;
				Internal.State := exASSETINT_STATE_IDLE;
			
				// Error
			ELSIF Internal.WriteEventData.Status <> ERR_FUB_BUSY THEN
				// Set status, remember state, go to error state
				StatusID := CreateErrorState(Internal.WriteEventData.Status, ADR('ERR: create new event'), Logger, exCOM_SEV_ERROR, ADR(Internal.State), ADR(Info.Diag.StatusID));
			END_IF
			
			// -------------------------------------------------------------------------------------------
			// Export all events
			// -------------------------------------------------------------------------------------------
		exASSETINT_STATE_EXPORT_EVENTS:
			Internal.ExportEventData.Enable := TRUE;
			Internal.ExportEventData.Device := DeviceName;
			Internal.ExportEventData.Logger := Logger;
			Internal.ExportEventData.RecordCount := exLink.RecordCount;
			Internal.ExportEventData.Memory := exLink.MemoryDb;
			Internal.ExportEventData.Configuration := exLink.Configuration.Export;
			Internal.ExportEventData();
		
			// -------------------------------------------------------------------------------------------
			// Event successful created
			IF Internal.ExportEventData.Status = ERR_OK THEN
				CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('export events ok'), Logger);
				
				ExportDone := TRUE;
				CommandBusy := FALSE;
				CommandDone := TRUE;

				StatusID := ERR_OK;
				Internal.State := exASSETINT_STATE_IDLE;
			
				// Error
			ELSIF Internal.ExportEventData.Status <> ERR_FUB_BUSY THEN
				// Set status, remember state, go to error state
				StatusID := CreateErrorState(Internal.ExportEventData.Status, ADR('ERR: export events'), Logger, exCOM_SEV_ERROR, ADR(Internal.State), ADR(Info.Diag.StatusID));
			END_IF
			
			// -------------------------------------------------------------------------------------------
			// Load link data
		exASSETINT_STATE_LOAD_LINK:
			Internal.ReadLinkData.Enable := TRUE;
			Internal.ReadLinkData.Device := ADR(StorageName);
			Internal.ReadLinkData.Logger := Logger;
			Internal.ReadLinkData.Link	 := ADR(exLink);
			Internal.ReadLinkData();
		
			// Link data successful restored
			IF Internal.ReadLinkData.Status = ERR_OK THEN
				CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('load link data restored'), Logger);				

				StatusID := ERR_OK;
				Internal.State := exASSETINT_STATE_INIT_2;

				// Link data does not exist
			ELSIF Internal.ReadLinkData.Status = fiERR_FILE_NOT_FOUND  THEN
				CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('no backup file found'), Logger);				

				StatusID := ERR_OK;
				Internal.State := exASSETINT_STATE_INIT_2;
			
				// Error
			ELSIF Internal.ReadLinkData.Status <> ERR_FUB_BUSY THEN
				// Set status, remember state, go to error state
				StatusID := CreateErrorState(Internal.ReadLinkData.Status, ADR('ERR: load link data'), Logger, exCOM_SEV_ERROR,  ADR(Internal.State), ADR(Info.Diag.StatusID));
			END_IF

			// -------------------------------------------------------------------------------------------
			// Save link data
		exASSETINT_STATE_SAVE_LINK:
			Internal.WriteLinkData.Enable := TRUE;
			Internal.WriteLinkData.Device := ADR(StorageName);
			Internal.WriteLinkData.Logger := Logger;
			Internal.WriteLinkData.Link := ADR(exLink);
			Internal.WriteLinkData();
		
			// Event successful created
			IF Internal.WriteLinkData.Status = ERR_OK THEN
				CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('save link data ok'), Logger);				

				StatusID := ERR_OK;		
				Internal.State := exASSETINT_STATE_IDLE;
			
				// Error
			ELSIF Internal.WriteLinkData.Status <> ERR_FUB_BUSY THEN
				// Set status, remember state, go to error state
				StatusID := CreateErrorState(Internal.WriteLinkData.Status, ADR('ERR: save link data'), Logger, exCOM_SEV_ERROR,  ADR(Internal.State), ADR(Info.Diag.StatusID));
			END_IF
			
			// -------------------------------------------------------------------------------------------
			// Error state
			// -------------------------------------------------------------------------------------------
		exASSETINT_STATE_ERROR:
			Error := TRUE;
      
			// Reset error state
			IF EDGEPOS(ErrorReset) THEN
				Internal.StateError := exASSETINT_STATE_NONE;
				Internal.State := exASSETINT_STATE_INIT_1;
			END_IF
	END_CASE;
	
END_FUNCTION_BLOCK



