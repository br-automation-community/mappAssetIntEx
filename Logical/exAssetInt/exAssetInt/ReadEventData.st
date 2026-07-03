// -------------------------------------------------------------------------------------------
// File version 1002
// -------------------------------------------------------------------------------------------
// Read event data
// -------------------------------------------------------------------------------------------
FUNCTION_BLOCK ReadEventData
	// -------------------------------------------------------------------------------------------
	// Reset everything when enable is false
	IF NOT Enable THEN
		Status := ERR_FUB_ENABLE_FALSE;
		State := 0;
	END_IF
	
	// Speed up read by executing function block twice
	FOR Override:=0 TO 2 DO
		CASE State OF
			// -------------------------------------------------------------------------------------------
			// Wait for enable
			0:
				IF EDGEPOS(Enable) THEN
					brsmemset(Memory, 0, CORE_EVENT_NUM_MAX*SIZEOF(RecordData));
					brsmemset(ADR(RecordIndexUsed), 0, SIZEOF(RecordIndexUsed));

					// Reset function blocks
					DirOpen_0.enable := FALSE;
					DirOpen_0();
					DirReadEx_0.enable := FALSE;
					DirReadEx_0();
					DirClose_0.enable := FALSE;
					DirClose_0();
					FileOpen_0.enable := FALSE;
					FileOpen_0();
					FileRead_0.enable := FALSE;
					FileRead_0();
					FileClose_0.enable := FALSE;
					FileClose_0();
	
					// Generate folder name
					NextFileNameReady := FALSE;
					NextFileNameGet	:= FALSE;
					
					Status := ERR_FUB_BUSY;
					StatusRead := ERR_OK;

					RecordCount := 0;
					FirstEntryTime := 0;
					FirstEntryRecord := 0;
					LastEntryTime := 0;
					LastEntryRecord := 0;
					CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('reading all events'), Logger);
					State := 1;
				END_IF
	
			// -------------------------------------------------------------------------------------------
			// Start reading folder
			1:
				DirOpen_0.enable := TRUE;
				DirOpen_0.pDevice := ADR(Device);
				DirOpen_0.pName := ADR(CORE_FOLDER_NAME);
				DirOpen_0();
		
				// File created successful
				IF DirOpen_0.status = ERR_OK THEN
					// Generate log entry
					TmpStr1 := 'open dir > ';
					brsstrcat(ADR(TmpStr1), ADR(CORE_FOLDER_NAME));
					CreateLoggerEntry(exASSETINT_LOG_ALL, ADR(TmpStr1), Logger);
					
					// Go to next step
					NextFileNameGet := TRUE;
					State := 2;
					
				// Error
				ELSIF DirOpen_0.status <> ERR_FUB_BUSY THEN
					Status := DirOpen_0.status;
					State := 0;
				END_IF
				
			// -------------------------------------------------------------------------------------------
			// Read next file name
			2:
				// Wait for dir read to finish
				IF NextFileNameReady THEN
					NextFileNameReady := FALSE;
					State := 4;
				END_IF
				
				// Finish if there are no files
				IF DirReadEx_0.status = fiERR_NO_MORE_ENTRIES THEN
					// Generate log entry
					TmpStr1 := 'read all events ok ';
					brsstrcat(ADR(TmpStr1), ADR(CORE_FOLDER_NAME));
					CreateLoggerEntry(exASSETINT_LOG_ALL, ADR(TmpStr1), Logger);
					State := 3;
				END_IF
				
			// -------------------------------------------------------------------------------------------
			// Finish reading folder
			3:
				DirClose_0.enable := TRUE;
				DirClose_0.ident := DirOpen_0.ident;
				DirClose_0();
		
				// Directory closed successful
				IF DirClose_0.status = ERR_OK THEN
					// Generate log entry
					TmpStr1 := 'close dir ok > ';
					brsstrcat(ADR(TmpStr1), ADR(CORE_FOLDER_NAME));
					CreateLoggerEntry(exASSETINT_LOG_ALL, ADR(TmpStr1), Logger);
					
					Status := ERR_OK;
					State := 0;
											
				// Error
				ELSIF DirClose_0.status <> ERR_FUB_BUSY THEN
					Status := DirClose_0.status;
					State := 0;
				END_IF
				
			// -------------------------------------------------------------------------------------------
			// Open event file
			4:
				// Generate file name
				FileName := CORE_FOLDER_NAME;
				brsstrcat(ADR(FileName), ADR('/'));
				brsstrcat(ADR(FileName), ADR(FileInfo_0.Filename));
				
				// Open file
				FileOpen_0.enable := TRUE;
				FileOpen_0.pDevice := ADR(Device);
				FileOpen_0.pFile := ADR(FileName);
				FileOpen_0.mode := fiREAD_ONLY;
				FileOpen_0();
		
				// File opened successful
				IF FileOpen_0.status = ERR_OK THEN
					// Generate log entry
					NextFileNameGet := TRUE;
					TmpStr1 := 'open event file ok > ';
					brsstrcat(ADR(TmpStr1), ADR(FileName));
					CreateLoggerEntry(exASSETINT_LOG_ALL, ADR(TmpStr1), Logger);
									
					// Make sure data has correct size
					IF FileOpen_0.filelen <> SIZEOF(RecordData) THEN
						TmpStr1 := 'data in event file has wrong size > ';
						brsstrcat(ADR(TmpStr1), ADR(FileName));
						CreateLoggerEntry(exASSETINT_LOG_ERROR, ADR(TmpStr1), Logger);
						StatusRead := ERR_ASSET_READ_RECORD_SIZE;
						
						State := 6;
					ELSE
						State := 5;
					END_IF
					
				// Error
				ELSIF FileOpen_0.status <> ERR_FUB_BUSY THEN
					Status := FileOpen_0.status;
					State := 0;
				END_IF	
			
			// -------------------------------------------------------------------------------------------
			// Read event data
			5:
				FileRead_0.enable := TRUE;
				FileRead_0.ident := FileOpen_0.ident;
				FileRead_0.pDest := ADR(RecordData);
				FileRead_0.len := FileOpen_0.filelen;
				FileRead_0();
		
				// File read successful
				IF FileRead_0.status = ERR_OK THEN
					// Generate log entry
					TmpStr1 := 'read event file ok > ';
					brsstrcat(ADR(TmpStr1), ADR(FileName));
					CreateLoggerEntry(exASSETINT_LOG_INFO, ADR(TmpStr1), Logger);
					
					// Check CRC
					CRC := CalcCrc(ADR(RecordData), SIZEOF(RecordData));
					IF CRC <> RecordData.CRC THEN
						// Generate log entry
						TmpStr1 := 'read event file CRC error > ';
						brsstrcat(ADR(TmpStr1), ADR(FileName));
						CreateLoggerEntry(exASSETINT_LOG_ERROR, ADR(TmpStr1), Logger);
						StatusRead := ERR_ASSET_READ_CRC;
					ELSE
						// Insert record
						InsertEventData(Memory, RecordCount, RecordData);
						
						// Remember file name index is used, ignore indexes outside the array
						brsstrcpy(ADR(TmpStr1), ADR(FileName) + FindInstr(ADR(FileName), ADR('#')) + 1);
						FileIndex := DINT_TO_UINT(brsatoi(ADR(TmpStr1)));
						IF FileIndex <= CORE_EVENT_NUM_MAX THEN
							RecordIndexUsed[FileIndex] := TRUE;
						END_IF
						
						RecordCount := RecordCount + 1;
					END_IF
					
					State := 6;
					
				// Error
				ELSIF FileRead_0.status <> ERR_FUB_BUSY THEN
					Status := FileRead_0.status;
					State := 6;
				END_IF
	
			// -------------------------------------------------------------------------------------------
			// Close file
			6:
				FileClose_0.enable := TRUE;
				FileClose_0.ident := FileOpen_0.ident;
				FileClose_0();
		
				// File closed successful
				IF FileClose_0.status = ERR_OK THEN
					// Generate log entry
					TmpStr1 := 'close event file ok > ';
					brsstrcat(ADR(TmpStr1), ADR(FileName));
					CreateLoggerEntry(exASSETINT_LOG_ALL, ADR(TmpStr1), Logger);
					
					// Auto delete corrupt file 
					IF StatusRead = ERR_ASSET_READ_RECORD_SIZE OR StatusRead = ERR_ASSET_READ_CRC THEN
						State := 7;						
					// Abort if there was a previous error, else proceed with next file
					ELSIF Status <> ERR_FUB_BUSY THEN						
						State := 0;
					// Finish reading files
					ELSIF DirReadEx_0.status = fiERR_NO_MORE_ENTRIES THEN
						// Generate log entry
						TmpStr1 := 'read all events ok ';
						brsstrcat(ADR(TmpStr1), ADR(CORE_FOLDER_NAME));
						CreateLoggerEntry(exASSETINT_LOG_ALL, ADR(TmpStr1), Logger);
						State := 3;
					ELSE
						State := 2;
					END_IF
					
				// Error
				ELSIF FileClose_0.status <> ERR_FUB_BUSY THEN
					Status := FileClose_0.status;
					State := 0;
				END_IF
				
			// -------------------------------------------------------------------------------------------
			// Delete corrupt file
			7:
				FileDelete_0.enable := TRUE;
				FileDelete_0.pDevice := ADR(Device);
				FileDelete_0.pName := ADR(FileName);
				FileDelete_0();
		
				// File delete successful
				IF FileDelete_0.status = ERR_OK THEN
					// Generate log entry
					TmpStr1 := 'delete corrupt event file ok > ';
					brsstrcat(ADR(TmpStr1), ADR(FileName));
					CreateLoggerEntry(exASSETINT_LOG_ALL, ADR(TmpStr1), Logger);
					
					Status := StatusRead;
					State := 0;
					
				// Error
				ELSIF FileDelete_0.status <> ERR_FUB_BUSY THEN
					Status := FileDelete_0.status;
					State := 0;
				END_IF			
		END_CASE;
	END_FOR;
	
	IF NextFileNameGet THEN
		DirReadEx_0.enable := TRUE;
		DirReadEx_0.ident := DirOpen_0.ident;
		DirReadEx_0.pData := ADR(FileInfo_0);
		DirReadEx_0.data_len := SIZEOF(FileInfo_0);
		DirReadEx_0();
		
		// New file found
		IF DirReadEx_0.status = ERR_OK AND FileInfo_0.Mode = fiFILE THEN
			IF brsstrcmp(ADR(FileInfo_0.Filename), ADR('.')) <> 0 AND brsstrcmp(ADR(FileInfo_0.Filename), ADR('..')) <> 0 THEN			
				// Generate log entry
				TmpStr1 := 'found file > ';
				brsstrcat(ADR(TmpStr1), ADR(FileInfo_0.Filename));
				CreateLoggerEntry(exASSETINT_LOG_ALL, ADR(TmpStr1), Logger);

				DirReadEx_0.enable := FALSE;
				DirReadEx_0();

				NextFileNameGet := FALSE;
				NextFileNameReady := TRUE;
			END_IF
	
		// No more entries
		ELSIF DirReadEx_0.status = fiERR_NO_MORE_ENTRIES THEN
			NextFileNameGet := FALSE;
			NextFileNameReady := TRUE;
					
		// Error
		ELSIF DirReadEx_0.status <> ERR_OK AND DirReadEx_0.status <> ERR_FUB_BUSY THEN
			Status := DirReadEx_0.status;
			State := 0;
		END_IF
	END_IF

END_FUNCTION_BLOCK

FUNCTION InsertEventData
	x := 0;
	y := 0;
	sort := 0;

	// Set up start values for iteration
	IF RecordCount <> 0 THEN
		y := RecordCount - 1;
	END_IF
	x := y;

	// Start itteration	search
	// Start iteration search
	WHILE y > 1 DO
		// Check current entry
		RecordMemory ACCESS Memory + x*SIZEOF(RecordData);
		sort := DiffDT(RecordMemory.TimeStart, RecordData.TimeStart);

		// Solve new search range
		IF y MOD 2 = 0 THEN
			y := y / 2;
		ELSE
			y := y / 2 + 1;
		END_IF

		// New range is lower or higher than current
		IF sort <> 16#FFFFFFFF THEN
			x := x + y;
			IF x > UINT_TO_INT(RecordCount) THEN
				x := UINT_TO_INT(RecordCount);
			END_IF
		ELSE
			x := x - y;
			IF x < 1 THEN
				x := 1;
			END_IF
		END_IF
	END_WHILE;    

	// New entry is this, next or previous
	RecordMemory ACCESS Memory + x*SIZEOF(RecordData);
	sort := DiffDT(RecordMemory.TimeStart, RecordData.TimeStart);

	IF sort <> 16#FFFFFFFF AND x <> UINT_TO_INT(RecordCount) THEN
		x := x + 1;
	ELSIF x > 0 THEN
		RecordMemory ACCESS Memory + (x - 1)*SIZEOF(RecordData);
		sort := DiffDT(RecordMemory.TimeStart, RecordData.TimeStart);
		IF sort = 16#FFFFFFFF THEN
			x := x - 1;
		END_IF
	END_IF

	// Move all entries backwards and fill in new entry
	brsmemmove(Memory + (x + 1)*SIZEOF(RecordData), Memory + x*SIZEOF(RecordData), (RecordCount - x)*SIZEOF(RecordData));
	brsmemcpy(Memory + x*SIZEOF(RecordData), ADR(RecordData), SIZEOF(RecordData));

	InsertEventData := TRUE;

END_FUNCTION

