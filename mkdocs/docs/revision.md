#### 03.07.2026

Version 1.5

* Harmonize function status
* Fix ExportEventData state machine stall in step 4: when the current record did not match the active export mode (for example RecordTypeUptime during job/shift export), no row was generated and neither state nor index advanced, leaving export stuck; now non-matching records are skipped and processing continues
* Fix CreateLoggerEntry robustness: LastMsg was an uninitialized function local compared against stack garbage while the log buffer was still empty; the ring buffer move used length LOG_LEN*(LOG_NUM-1) at a stride of LOG_LEN+1 (STRING[100] occupies 101 bytes), leaving stale bytes in the oldest entry; oversized log messages overwrote the caller's message buffer and were dropped entirely instead of being logged with a local truncated copy; removed a dead duplicate brsitoa(day) call
* Fix exAssetIntCheckPreq missing MemoryShift null check: the shift list UI could pass a 0 pointer into exAssetIntBufferUI when only MemoryDb/MemoryJob/MemoryTimeline were checked
* Fix exAssetIntFilterListUI: DT_TO_DTStructure_0.second and .millisec were never set before converting the filter dialog date to a DT value, so the From/Until filter boundaries were shifted by whatever stack garbage happened to be in those fields
* Reset RecordStart when entering STATE_UI_BUFFER in exAssetIntJobListUI, exAssetIntShiftListUI and exAssetIntTimelineUI: a filter or sort change could leave RecordStart beyond the newly filtered record count, showing an empty list even though matching data existed
* Fix constant mixups in list scrolling: exAssetIntScrollListUI computed the scrollbar range with the hardcoded UI_TIMELINE_IDX instead of the ListMaxCount parameter passed in by the caller, and exAssetIntShiftListUI passed UI_TIMELINE_IDX+1 instead of UI_SHIFT_LIST_IDX+1 into the scroll handler; both currently evaluate to the same value but would silently break if either constant is changed independently
* Fix CalcStats downtime rate precision and division by zero: ScheduledDowntimeRate/UnscheduledDowntimeRate divided as integers before converting to REAL, quantizing the result and rounding small downtimes to 0; NominalProductionTime/GoodProductionTime divided 3600 by NominalProductionRate with no guard, producing infinity (propagated into a UDINT conversion) when the rate is configured as 0
* Fix LOAD_LINK error path leaving the core stuck: a corrupt backup (wrong size or version) is already deleted by ReadLinkData, but the state machine still went to the generic error state instead of reinitializing; now treated like a missing backup file and restarted fresh
* Remove dead CreateDirStructure.st: referenced a nonexistent CORE_EVENT_DIR_MAX constant, was not registered in IEC.lby and was never called

#### 03.07.2026

Version 1.4

* Fix out of bounds read in exAssetIntTimelineUI bar graph prescan: the loop ran inclusive to RecordCount and added RecordStart to the index, reading up to hundreds of KB past the timeline buffer once the list was scrolled; now bounded the same way as the sibling display loop (UI_TIMELINE_IDX page size, RecordStart + index < RecordCount)
* Fix ExportEventData timeline export checking the wrong configuration flag (Configuration.JobStatistics instead of Configuration.Timeline), so the timeline export silently followed the job export setting and the Timeline flag had no effect
* Fix %M placeholder in ExportEventData: file name and export row timestamps replaced %M with the month value instead of the minute (4 occurrences), so the minute was never exported and the month appeared twice
* Fix ExportEventData off-by-one: the newest record (idx 0) was decremented past/overwritten before being written, so it was always missing from the job/shift/timeline CSV export
* Fix uninitialized function local DiffTime in TrackShiftChange: on most cyclic calls it held stack garbage, occasionally triggering a false shift change that reset the shift statistics and created events every cycle
* Fix uninitialized function locals: exAssetIntBufferUI (RecordCount, y) wrote with undefined offset into the UI buffer memory (memory corruption)
* Fix uninitialized function return values in FindInstr and CalcCrc
* Fix out of bounds write to RecordIndexUsed: index parsed from event file name was used without range check (ReadEventData and core store event)
* Reject files in the event folder that do not match the 'event#<index>' name pattern before opening them, log an error instead of processing them
* Fix out of bounds write in ReadConfiguration: file size was not checked against the configuration structure before reading (memory corruption on mismatched/old configuration file)
* Fix out of bounds write in InsertEventData: RecordCount was not capped against CORE_EVENT_NUM_MAX before inserting into the record buffer, more than 500 valid event files would write past the buffer (memory corruption)
* Fix UINT underflow in exAssetIntScrollListUI: RecordCount - ListMaxCount wrapped around to a large positive value when there were fewer entries than the list page size, bypassing the RecordStart < 0 correction and causing an out of bounds read when rendering the list
* Fix missing null termination in NormalizeDateTime: the LREAL return value was used as a string buffer without being zeroed first, so a following brsstrlen/brsstrcat during export could read past the return value and overflow the export buffer

#### 21.10.2025 

Version 1.3

* Fix division by zero when record number is 0
* Fix enum memory violation
* Fix dir create after error reset

#### 16.09.2025

* Update project to AS6

#### 14.01.2025 

Version 1.2

* Check remanent backup data against structure version to avoid data corruption

#### 20.12.2024 

Version 1.1

* Handle division by zero
* Fix power off and power into the same shift days later does not trigger event
* Shift end event now uses power off date and time
* Fixed typos in function calls

#### 14.11.2024

First release
