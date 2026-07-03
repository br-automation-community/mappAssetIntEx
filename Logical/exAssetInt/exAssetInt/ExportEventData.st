// -------------------------------------------------------------------------------------------
// File version 1002
// -------------------------------------------------------------------------------------------
// Read event data
// -------------------------------------------------------------------------------------------
FUNCTION_BLOCK ExportEventData
	// -------------------------------------------------------------------------------------------
	// Reset everything when enable is false
	IF NOT Enable THEN
		Status := ERR_FUB_ENABLE_FALSE;
		State := 0;		
		RETURN;
	END_IF
	
	CASE State OF
		// -------------------------------------------------------------------------------------------
		// Wait for enable
		// -------------------------------------------------------------------------------------------
		0:
			IF Enable THEN
			
				// -------------------------------------------------------------------------------------------
				// Create file name
				RTC_gettime(ADR(RtcGettime));
				ExportType := ExportTypeJob;
				
				// Make sure we have data that can be exported
				IF RecordCount > 0 THEN
					Status := ERR_FUB_BUSY;
					CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('start exporting data'), Logger);

					State := 1;
				ELSE

					CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('no data to export'), Logger);
				END_IF
			END_IF

		// -------------------------------------------------------------------------------------------
		// Generate file name
		// -------------------------------------------------------------------------------------------
		1:
			// -------------------------------------------------------------------------------------------
			// Reset function blocks
			FileCreate_0.enable := FALSE;
			FileCreate_0();
			FileWrite_0.enable := FALSE;
			FileWrite_0();
			FileClose_0.enable := FALSE;
			FileClose_0();
			
			// -------------------------------------------------------------------------------------------
			// Export job data
			IF ExportType = ExportTypeJob THEN
				IF Configuration.JobStatistics THEN
					FileName := Configuration.JobStatisticsFileNamePattern;
				ELSE
					ExportType := ExportTypeShift;
				END_IF
			END_IF

			// -------------------------------------------------------------------------------------------
			// Export shift data
			IF ExportType = ExportTypeShift THEN
				IF Configuration.ShiftStatistics THEN
					FileName := Configuration.ShiftStatisticsFileNamePattern;
				ELSE
					ExportType := ExportTypeTimeline;
				END_IF
			END_IF
			
			// -------------------------------------------------------------------------------------------
			// Export timeline
			IF ExportType = ExportTypeTimeline THEN
				IF Configuration.JobStatistics THEN
					FileName := Configuration.TimelineFileNamePattern;
				ELSE
					State := 0;
					Status := ERR_OK;
					RETURN;
				END_IF
			END_IF

			// -------------------------------------------------------------------------------------------
			// Create date and time information
			ReplaceDateTime(ADR(FileName), ADR('%d'), RtcGettime.day);				
			ReplaceDateTime(ADR(FileName), ADR('%m'), RtcGettime.month);
			ReplaceDateTime(ADR(FileName), ADR('%Y'), RtcGettime.year);
			
			ReplaceDateTime(ADR(FileName), ADR('%S'), RtcGettime.second);				
			ReplaceDateTime(ADR(FileName), ADR('%M'), RtcGettime.month);
			ReplaceDateTime(ADR(FileName), ADR('%H'), RtcGettime.hour);

			idx := RecordCount - 1;
			Offset := 0;
			Status := ERR_FUB_BUSY;
			CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('start exporting data'), Logger);
			
			State := 2;
			
		// -------------------------------------------------------------------------------------------
		// Delete old export file
		// -------------------------------------------------------------------------------------------
		2:
			FileDelete_0.enable := TRUE;
			FileDelete_0.pDevice := ADR(Device);
			FileDelete_0.pName := ADR(FileName);
			FileDelete_0();
	
			// -------------------------------------------------------------------------------------------
			// File delete successful
			IF FileDelete_0.status = ERR_OK  OR FileDelete_0.status = fiERR_FILE_NOT_FOUND THEN
				// Generate log entry
				TmpStr1 := 'delete old file ok > ';
				brsstrcat(ADR(TmpStr1), ADR(FileName));
				CreateLoggerEntry(exASSETINT_LOG_ALL, ADR(TmpStr1), Logger);

				State := 3;
				
			// Error
			ELSIF FileDelete_0.status <> ERR_FUB_BUSY THEN
				Status := FileDelete_0.status;
				State := 0;
			END_IF
		
		// -------------------------------------------------------------------------------------------
		// Create export file
		// -------------------------------------------------------------------------------------------
		3:
			FileCreate_0.enable := TRUE;
			FileCreate_0.pDevice := ADR(Device);
			FileCreate_0.pFile := ADR(FileName);
			FileCreate_0();
	
			// -------------------------------------------------------------------------------------------
			// File created successful
			IF FileCreate_0.status = ERR_OK THEN
				// Generate log entry
				TmpStr1 := 'create event file > ';
				brsstrcat(ADR(TmpStr1), ADR(FileName));
				CreateLoggerEntry(exASSETINT_LOG_ALL, ADR(TmpStr1), Logger);
				
				// Create header data depending on export file
				brsmemset(ADR(Buffer), 0, SIZEOF(Buffer));
				IF ExportType = ExportTypeJob THEN
					brsstrcat(ADR(Buffer), ADR(EXPORT_JOB_TITEL));
					brsstrcat(ADR(Buffer), ADR('$R'));
					brsstrcat(ADR(Buffer), ADR(EXPORT_JOB_HEADER));
					brsstrcat(ADR(Buffer), ADR('$R'));
				ELSIF ExportType = ExportTypeShift THEN
					brsstrcat(ADR(Buffer), ADR(EXPORT_SHIFT_TITEL));
					brsstrcat(ADR(Buffer), ADR('$R'));
					brsstrcat(ADR(Buffer), ADR(EXPORT_SHIFT_HEADER));
					brsstrcat(ADR(Buffer), ADR('$R'));
				ELSE
					brsstrcat(ADR(Buffer), ADR(EXPORT_TIMELINE_TITEL));
					brsstrcat(ADR(Buffer), ADR('$R'));
					brsstrcat(ADR(Buffer), ADR(EXPORT_TIMELINE_HEADER));
					brsstrcat(ADR(Buffer), ADR('$R'));
				END_IF
					
				State := 5;
				
			// Error
			ELSIF FileCreate_0.status <> ERR_FUB_BUSY THEN
				Status := FileCreate_0.status;
				State := 0;
			END_IF		
		
		// -------------------------------------------------------------------------------------------
		// Generate data
		// -------------------------------------------------------------------------------------------
		4:		
			// Reset buffer, copy new record
			brsmemset(ADR(Buffer), 0, SIZEOF(Buffer));
			brsmemcpy(ADR(RecordDataIntern), Memory + idx*SIZEOF(RecordDataIntern), SIZEOF(RecordDataIntern));

			// -------------------------------------------------------------------------------------------
			// Create row string for job and shift export
			IF (RecordDataIntern.EventType = RecordTypeJob AND ExportType = ExportTypeJob) OR (RecordDataIntern.EventType = RecordTypeShift AND ExportType = ExportTypeShift) THEN
				DT_TO_DTStructure(RecordDataIntern.TimeStart, ADR(DTStructure_0));
				TmpStr1 := Configuration.TimestampPattern;
							
				ReplaceDateTime(ADR(TmpStr1), ADR('%d'), DTStructure_0.day);				
				ReplaceDateTime(ADR(TmpStr1), ADR('%m'), DTStructure_0.month);
				ReplaceDateTime(ADR(TmpStr1), ADR('%Y'), DTStructure_0.year);
				ReplaceDateTime(ADR(TmpStr1), ADR('%S'), DTStructure_0.second);				
				ReplaceDateTime(ADR(TmpStr1), ADR('%M'), DTStructure_0.month);
				ReplaceDateTime(ADR(TmpStr1), ADR('%H'), DTStructure_0.hour);

				brsstrcat(ADR(Buffer), ADR(TmpStr1));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));

				DT_TO_DTStructure(RecordDataIntern.TimeEnd, ADR(DTStructure_0));
				TmpStr1 := Configuration.TimestampPattern;
							
				ReplaceDateTime(ADR(TmpStr1), ADR('%d'), DTStructure_0.day);				
				ReplaceDateTime(ADR(TmpStr1), ADR('%m'), DTStructure_0.month);
				ReplaceDateTime(ADR(TmpStr1), ADR('%Y'), DTStructure_0.year);
				ReplaceDateTime(ADR(TmpStr1), ADR('%S'), DTStructure_0.second);				
				ReplaceDateTime(ADR(TmpStr1), ADR('%M'), DTStructure_0.month);
				ReplaceDateTime(ADR(TmpStr1), ADR('%H'), DTStructure_0.hour);

				brsstrcat(ADR(Buffer), ADR(TmpStr1));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));

				brsstrcat(ADR(Buffer), ADR(RecordDataIntern.JobName));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
				brsstrcat(ADR(Buffer), ADR(RecordDataIntern.CurrentUser));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
				brsstrcat(ADR(Buffer), ADR(RecordDataIntern.AdditionalData));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
				
				brsitoa(RecordDataIntern.TargetPieces, ADR(TmpStr1));
				brsstrcat(ADR(Buffer), ADR(TmpStr1));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
	
				brsitoa(RecordDataIntern.GoodPieces, ADR(TmpStr1));
				brsstrcat(ADR(Buffer), ADR(TmpStr1));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
	
				brsitoa(RecordDataIntern.RejectPieces, ADR(TmpStr1));
				brsstrcat(ADR(Buffer), ADR(TmpStr1));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
	
				NormalizeFloat(RecordDataIntern.BadPieceRate, ADR(TmpStr1), Configuration);
				brsstrcat(ADR(Buffer), ADR(TmpStr1));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
	
				lrealStr := NormalizeDateTime(RecordDataIntern.TotalTime.Hours);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(':'));
				lrealStr := NormalizeDateTime(RecordDataIntern.TotalTime.Minutes);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(':'));
				lrealStr := NormalizeDateTime(RecordDataIntern.TotalTime.Seconds);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
	
				lrealStr := NormalizeDateTime(RecordDataIntern.ScheduledDowntime.Hours);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(':'));
				lrealStr := NormalizeDateTime(RecordDataIntern.ScheduledDowntime.Minutes);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(':'));
				lrealStr := NormalizeDateTime(RecordDataIntern.ScheduledDowntime.Seconds);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
	
				lrealStr := NormalizeDateTime(RecordDataIntern.UnscheduledDowntime.Hours);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(':'));
				lrealStr := NormalizeDateTime(RecordDataIntern.UnscheduledDowntime.Minutes);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(':'));
				lrealStr := NormalizeDateTime(RecordDataIntern.UnscheduledDowntime.Seconds);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
	
				lrealStr := NormalizeDateTime(RecordDataIntern.Uptime.Hours);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(':'));
				lrealStr := NormalizeDateTime(RecordDataIntern.Uptime.Minutes);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(':'));
				lrealStr := NormalizeDateTime(RecordDataIntern.Uptime.Seconds);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
	
				lrealStr := NormalizeDateTime(RecordDataIntern.GoodProductionTime.Hours);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(':'));
				lrealStr := NormalizeDateTime(RecordDataIntern.GoodProductionTime.Minutes);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(':'));
				lrealStr := NormalizeDateTime(RecordDataIntern.GoodProductionTime.Seconds);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
	
				lrealStr := NormalizeDateTime(RecordDataIntern.NominalProductionTime.Hours);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(':'));
				lrealStr := NormalizeDateTime(RecordDataIntern.NominalProductionTime.Minutes);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(':'));
				lrealStr := NormalizeDateTime(RecordDataIntern.NominalProductionTime.Seconds);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));

				NormalizeFloat(RecordDataIntern.NominalProductionTimeRate, ADR(TmpStr1), Configuration);
				brsstrcat(ADR(Buffer), ADR(TmpStr1));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
	
				NormalizeFloat(RecordDataIntern.ScheduledDowntimeRate, ADR(TmpStr1), Configuration);
				brsstrcat(ADR(Buffer), ADR(TmpStr1));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
	
				NormalizeFloat(RecordDataIntern.UnscheduledDowntimeRate, ADR(TmpStr1), Configuration);
				brsstrcat(ADR(Buffer), ADR(TmpStr1));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
	
				NormalizeFloat(RecordDataIntern.CurrentProductionRate, ADR(TmpStr1), Configuration);
				brsstrcat(ADR(Buffer), ADR(TmpStr1));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
	
				brsstrcat(ADR(Buffer), ADR(RecordDataIntern.ShiftName));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
				brsstrcat(ADR(Buffer), ADR('$R'));

				State := 5;
			END_IF
			
			// -------------------------------------------------------------------------------------------
			// Export data for timeline
			
			IF (RecordDataIntern.EventType >= RecordTypeNoShift AND ExportType = ExportTypeTimeline) THEN
				// Create start time
				DT_TO_DTStructure(RecordDataIntern.TimeStart, ADR(DTStructure_0));
				TmpStr1 := Configuration.TimestampPattern;
							
				ReplaceDateTime(ADR(TmpStr1), ADR('%d'), DTStructure_0.day);				
				ReplaceDateTime(ADR(TmpStr1), ADR('%m'), DTStructure_0.month);
				ReplaceDateTime(ADR(TmpStr1), ADR('%Y'), DTStructure_0.year);
				ReplaceDateTime(ADR(TmpStr1), ADR('%S'), DTStructure_0.second);				
				ReplaceDateTime(ADR(TmpStr1), ADR('%M'), DTStructure_0.month);
				ReplaceDateTime(ADR(TmpStr1), ADR('%H'), DTStructure_0.hour);

				brsstrcat(ADR(Buffer), ADR(TmpStr1));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));

				// Add shift name
				brsstrcat(ADR(Buffer), ADR(RecordDataIntern.ShiftName));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
				
				// Event is scheduled downtime
				IF RecordDataIntern.EventType = RecordTypeNoShift THEN
					brsstrcat(ADR(Buffer), ADR('No shift'));
				// Event is scheduled downtime
				ELSIF RecordDataIntern.EventType = RecordTypeDowntimeScheduled THEN
					brsstrcat(ADR(Buffer), ADR('Scheduled Downtime'));
				// Event is unscheduled downtime
				ELSIF RecordDataIntern.EventType = RecordTypeDowntimeUnscheduled THEN
					brsstrcat(ADR(Buffer), ADR('Unscheduled Downtime'));	
				// Event is new shift
				ELSE
					brsstrcat(ADR(Buffer), ADR('Uptime'));
				END_IF
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));			
				
				// Additional data
				brsstrcat(ADR(Buffer), ADR(RecordDataIntern.AdditionalData));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));

				// Total time
				lrealStr := NormalizeDateTime(RecordDataIntern.TotalTime.Hours);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(':'));
				lrealStr := NormalizeDateTime(RecordDataIntern.TotalTime.Minutes);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(':'));
				lrealStr := NormalizeDateTime(RecordDataIntern.TotalTime.Seconds);
				brsstrcat(ADR(Buffer), ADR(lrealStr));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
				
				// Job name
				brsstrcat(ADR(Buffer), ADR(RecordDataIntern.JobName));
				brsstrcat(ADR(Buffer), ADR(Configuration.ColumnSeparator));
				
				brsstrcat(ADR(Buffer), ADR('$R'));

				State := 5;			
			END_IF

			// Increase counter
			IF idx = 0 THEN
				State := 6;
			ELSE
				idx := idx - 1;
			END_IF
			
		// -------------------------------------------------------------------------------------------
		// Write data
		// -------------------------------------------------------------------------------------------
		5:			
			FileWrite_0.enable := TRUE;
			FileWrite_0.ident := FileCreate_0.ident;
			FileWrite_0.offset := Offset;
			FileWrite_0.pSrc := ADR(Buffer);
			FileWrite_0.len := brsstrlen(ADR(Buffer));
			FileWrite_0();
	
			// File created successful
			IF FileWrite_0.status = ERR_OK THEN
				// Generate log entry
				TmpStr1 := 'write idx ok > ';
				brsitoa(idx, ADR(TmpStr2));
				brsstrcat(ADR(TmpStr1), ADR(TmpStr2));
				CreateLoggerEntry(exASSETINT_LOG_ALL, ADR(TmpStr1), Logger);
			
				// Remember offset
				Offset := Offset + FileWrite_0.len;
				
				// Go to next step
				IF idx > 0 THEN
					State := 4;
				ELSE
					State := 6;
				END_IF
				
				// Error
			ELSIF FileWrite_0.status <> ERR_FUB_BUSY THEN
				Status := FileWrite_0.status;
				State := 0;
			END_IF

			// -------------------------------------------------------------------------------------------
			// Close file
			// -------------------------------------------------------------------------------------------
		6:
			FileClose_0.enable := TRUE;
			FileClose_0.ident := FileCreate_0.ident;
			FileClose_0();
	
			// File created successful
			IF FileClose_0.status = ERR_OK THEN
				// Generate log entry
				TmpStr1 := 'close export file ok > ';
				brsstrcat(ADR(TmpStr1), ADR(FileName));
				CreateLoggerEntry(exASSETINT_LOG_ALL, ADR(TmpStr1), Logger);
								
				// Proceed with shift export
				IF ExportType = ExportTypeJob THEN
					ExportType := ExportTypeShift;
					State := 1;
					// Proceed with timeline export
				ELSIF ExportType = ExportTypeShift THEN
					ExportType := ExportTypeTimeline;
					State := 1;
				ELSE
					// Finish up
					Status := ERR_OK;
					State := 0;
				END_IF
				
				// Error
			ELSIF FileClose_0.status <> ERR_FUB_BUSY THEN
				Status := FileClose_0.status;
				State := 0;
			END_IF
	END_CASE;

END_FUNCTION_BLOCK

// -------------------------------------------------------------------------------------------
// Format float according to configuration																	
// -------------------------------------------------------------------------------------------
FUNCTION NormalizeFloat
	brsftoa(value, ADR(tmpStr));
	idx := FindInstr(ADR(tmpStr), ADR('.')) + configuration.DecimalDigits + 1;
	IF idx >= brsstrlen(ADR(tmpStr)) THEN
		brsstrcpy(output, ADR(tmpStr));
	ELSE
		brsmemcpy(output, ADR(tmpStr), idx);
		brsmemset(output + idx, 0, 1);
	END_IF
	ReplaceString(output, ADR('.'), ADR(configuration.DecimalMark));
	
	NormalizeFloat := TRUE;
END_FUNCTION

// -------------------------------------------------------------------------------------------
// Add additional 0 when value is < 10																	
// -------------------------------------------------------------------------------------------
FUNCTION NormalizeDateTime
	// Zero the LREAL return value first so the string copied below is always null terminated,
	// otherwise brsstrlen on the caller side (ReplaceDateTime/ReplaceString) can run past the
	// 8 byte return value into adjacent memory
	brsmemset(ADR(NormalizeDateTime), 0, SIZEOF(NormalizeDateTime));

	IF(value < 10) THEN
		TmpStr1 := '0';
	ELSE
		TmpStr1 := '';
	END_IF
	brsitoa(value, ADR(TmpStr2));
	brsstrcat(ADR(TmpStr1), ADR(TmpStr2));

	brsmemcpy(ADR(NormalizeDateTime), ADR(TmpStr1), brsstrlen(ADR(TmpStr1)));
	
END_FUNCTION

// -------------------------------------------------------------------------------------------
// Find and replace date and time information																	
// -------------------------------------------------------------------------------------------
FUNCTION ReplaceDateTime
	lrealStr := NormalizeDateTime(value);
	ReplaceString(dataSTR, searchSTR, ADR(lrealStr));
	
	ReplaceDateTime := TRUE;
END_FUNCTION

// -------------------------------------------------------------------------------------------
// Find and replace string																	
// -------------------------------------------------------------------------------------------
FUNCTION ReplaceString
	IF (brsstrlen(dataSTR) >= brsstrlen(searchSTR)) THEN
		FOR idx:=0 TO brsstrlen(dataSTR) - brsstrlen(searchSTR) DO
			IF (brsmemcmp(dataSTR + idx, searchSTR, brsstrlen(searchSTR)) = 0) THEN
				// Move data around
				brsmemmove(dataSTR + idx + brsstrlen(replaceSTR), dataSTR + idx + brsstrlen(searchSTR), brsstrlen(dataSTR) - brsstrlen(searchSTR) + 1);
				brsmemcpy(dataSTR + idx, replaceSTR, brsstrlen(replaceSTR));
				// Set found flag and exit if only one hit is needed
				ReplaceString := TRUE;
				// Correct index for next search
				IF(brsstrlen(replaceSTR) > 0) THEN
					idx := idx + brsstrlen(replaceSTR);
				END_IF
				idx := idx - 1;
				// Exit if no data is left
				IF (brsstrlen(dataSTR) = 0 OR brsstrlen(dataSTR) < brsstrlen(searchSTR)) THEN
					EXIT;
				END_IF
			END_IF
		END_FOR;
	END_IF
END_FUNCTION
