// -------------------------------------------------------------------------------------------
// File version 1001
// ------------------------------------------------------------------------------------------- 
// Create internal memory 
// ------------------------------------------------------------------------------------------- 
FUNCTION_BLOCK CreateMemory 
	// ------------------------------------------------------------------------------------------- 
	// Reset everything when enable is false 
	IF NOT Enable THEN 
		DatObjCreate_0.enable := FALSE; 
		DatObjCreate_0(); 
 
		MemoryType := exASSETINT_MEM_DB; 
		Status := ERR_FUB_ENABLE_FALSE; 
		State := 0;		 
		RETURN; 
	END_IF 
	 
	CASE State OF 
		// ------------------------------------------------------------------------------------------- 
		// Wait for enable 
		0: 
			IF Enable THEN 
				Cnt := 0; 
				TmpStr1 := 'AsDb_0'; 
				Status := ERR_FUB_BUSY; 
				CreateLoggerEntry(exASSETINT_LOG_INFO, ADR('creating internal memory'), Logger); 
				State := 1; 
			END_IF 
 
			// ------------------------------------------------------------------------------------------- 
			// Generate new data module 
		1: 
			DatObjCreate_0.enable := TRUE; 
			DatObjCreate_0.pName := ADR(TmpStr1); 
			DatObjCreate_0.len := Size; 
			DatObjCreate_0.MemType := doTEMP; 
			DatObjCreate_0.Option := doNO_CS;	 
			DatObjCreate_0(); 
	 
			// Data module created successful  
			IF DatObjCreate_0.status = ERR_OK THEN 
				// Created working memory 
				IF MemoryType = exASSETINT_MEM_DB THEN 
					// Generate log entry 
					TmpStr2 := 'create db memory module ok > '; 
					brsstrcat(ADR(TmpStr2), ADR(TmpStr1)); 
					CreateLoggerEntry(exASSETINT_LOG_ALL, ADR(TmpStr2), Logger); 
					 
					// Reset memory, set up next memory 
					brsmemset(DatObjCreate_0.pDatObjMem, 0, Size); 
					Cnt := 0; 
					MemoryDb := DatObjCreate_0.pDatObjMem; 
					MemoryType := exASSETINT_MEM_JOB; 
					TmpStr1 := 'AsWr_0'; 
				ELSIF MemoryType = exASSETINT_MEM_JOB THEN 
					// Generate log entry 
					TmpStr2 := 'create job memory module ok > '; 
					brsstrcat(ADR(TmpStr2), ADR(TmpStr1)); 
					CreateLoggerEntry(exASSETINT_LOG_ALL, ADR(TmpStr2), Logger); 
 
					// Reset memory, set up next memory 
					brsmemset(DatObjCreate_0.pDatObjMem, 0, Size); 
					Cnt := 0; 
					MemoryJob := DatObjCreate_0.pDatObjMem; 
					MemoryType := exASSETINT_MEM_SHIFT; 
					TmpStr1 := 'AsSh_0'; 
				ELSIF MemoryType = exASSETINT_MEM_SHIFT THEN 
					// Generate log entry 
					TmpStr2 := 'create shift memory module ok > '; 
					brsstrcat(ADR(TmpStr2), ADR(TmpStr1)); 
					CreateLoggerEntry(exASSETINT_LOG_ALL, ADR(TmpStr2), Logger); 
 
					// Reset memory, set up next memory 
					brsmemset(DatObjCreate_0.pDatObjMem, 0, Size); 
					Cnt := 0; 
					MemoryShift := DatObjCreate_0.pDatObjMem; 
					MemoryType := exASSETINT_MEM_TIMELINE; 
					TmpStr1 := 'AsTl_0'; 
				ELSIF MemoryType = exASSETINT_MEM_TIMELINE THEN 
					// Generate log entry 
					TmpStr2 := 'create timeline memory module ok > '; 
					brsstrcat(ADR(TmpStr2), ADR(TmpStr1)); 
					CreateLoggerEntry(exASSETINT_LOG_ALL, ADR(TmpStr2), Logger); 
 
					// Reset memory, finish up 
					brsmemset(DatObjCreate_0.pDatObjMem, 0, Size); 
					MemoryTimeline := DatObjCreate_0.pDatObjMem; 
					Status := ERR_OK; 
					State := 0; 
				END_IF 
					 
				DatObjCreate_0.enable := FALSE; 
				DatObjCreate_0(); 
								 
				// Data module already exists 
			ELSIF DatObjCreate_0.status = doERR_DUPOBJECT  THEN 
				// Generate log entry 
				TmpStr2 := 'module already exists > '; 
				brsstrcat(ADR(TmpStr2), ADR(TmpStr1)); 
				CreateLoggerEntry(exASSETINT_LOG_ALL, ADR(TmpStr2), Logger); 
				 
				// Increase module number, generate new module name 
				Cnt := Cnt + 1; 
				IF Cnt < 10 THEN 
					brsmemset(ADR(TmpStr1) + brsstrlen(ADR(TmpStr1)) - 1, 0, 1); 
				ELSE 
					brsmemset(ADR(TmpStr1) + brsstrlen(ADR(TmpStr1)) - 2, 0, 2); 
				END_IF 
				brsitoa(Cnt, ADR(TmpStr2)); 
				brsstrcat(ADR(TmpStr1), ADR(TmpStr2)); 
 
				DatObjCreate_0.enable := FALSE; 
				DatObjCreate_0(); 
 
				// Error 
			ELSIF DatObjCreate_0.status <> ERR_FUB_BUSY THEN 
				Status := DatObjCreate_0.status; 
				State := 0; 
			END_IF 
 
	END_CASE; 
 
END_FUNCTION_BLOCK 
 
