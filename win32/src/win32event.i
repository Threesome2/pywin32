/* File : win32event.i */
// @doc

%module win32event // A module which provides an interface to the win32 event/wait API

%{
//#define UNICODE
#ifndef MS_WINCE
#include "winsock2.h"
#include "mswsock.h"
#endif
%}

%include "typemaps.i"
%include "pywin32.i"


#define WAIT_FAILED WAIT_FAILED
#define WAIT_OBJECT_0  WAIT_OBJECT_0

#define WAIT_ABANDONED WAIT_ABANDONED
#define WAIT_ABANDONED_0 WAIT_ABANDONED_0

#define WAIT_TIMEOUT WAIT_TIMEOUT
#define WAIT_IO_COMPLETION WAIT_IO_COMPLETION

#define MAXIMUM_WAIT_OBJECTS MAXIMUM_WAIT_OBJECTS

#define INFINITE INFINITE

#define QS_ALLEVENTS QS_ALLEVENTS // An input, WM_TIMER, WM_PAINT, WM_HOTKEY, or posted message is in the queue.

#define QS_ALLINPUT QS_ALLINPUT // Any message is in the queue.

#ifndef MS_WINCE
#define QS_HOTKEY QS_HOTKEY // A WM_HOTKEY message is in the queue.
#endif

#define QS_INPUT QS_INPUT // An input message is in the queue.

#define QS_KEY QS_KEY // A WM_KEYUP, WM_KEYDOWN, WM_SYSKEYUP, or WM_SYSKEYDOWN message is in the queue.

#define QS_MOUSE QS_MOUSE // A WM_MOUSEMOVE message or mouse-button message (WM_LBUTTONUP, WM_RBUTTONDOWN, and so on).

#define QS_MOUSEBUTTON QS_MOUSEBUTTON // A mouse-button message (WM_LBUTTONUP, WM_RBUTTONDOWN, and so on).

#define QS_MOUSEMOVE QS_MOUSEMOVE // A WM_MOUSEMOVE message is in the queue.

#define QS_PAINT QS_PAINT // A WM_PAINT message is in the queue. 

#define QS_POSTMESSAGE QS_POSTMESSAGE // A posted message (other than those just listed) is in the queue. 

#define QS_SENDMESSAGE QS_SENDMESSAGE // A message sent by another thread or application is in the queue. 

#define QS_TIMER QS_TIMER // A WM_TIMER message is in the queue. 

#define EVENT_ALL_ACCESS EVENT_ALL_ACCESS // Specifies all possible access flags for the event object. 
 
#define EVENT_MODIFY_STATE EVENT_MODIFY_STATE // Enables use of the event handle in the SetEvent and ResetEvent�functions to modify the event�s state. 
 
#define SYNCHRONIZE SYNCHRONIZE // Windows NT only:�Enables use of the event handle in any of the wait functions�to wait for the event�s state to be signaled.

#if(_WIN32_WINNT >= 0x0400)
// XXX - WTF?
//BOOLAPI CancelWaitableTimer(HANDLE handle);

#end

// @pyswig <o PyHANDLE>|CreateEvent|Creates a waitable event
// @rdesc The result is a handle to the created object
PyHANDLE CreateEvent(
    SECURITY_ATTRIBUTES *inNullSA,   // @pyparm <o PySECURITY_ATTRIBUTES>|sa||The security attributes, or None
    BOOL bManualReset,	// @pyparm int|bManualReset||flag for manual-reset event 
    BOOL bInitialState,	// @pyparm int|bInitialState||flag for initial state 
    TCHAR *INPUT_NULLOK 	// @pyparm <o PyIUnicode>|objectName||event-object name, or None
);

// @pyswig <o PyHANDLE>|CreateMutex|Creates a mutex
// @rdesc The result is a handle to the created object
PyHANDLE CreateMutex(
    SECURITY_ATTRIBUTES *inNullSA, // @pyparm object|securityAttributes||Placeholder for furture security object, or None
    BOOL bInitialOwner,	// @pyparm int|bInitialOwner||flag for initial ownership 
    TCHAR * INPUT_NULLOK 	// @pyparm <o PyIUnicode>|mutexName||mutex-object name, or None
  );

#ifndef MS_WINCE
// @pyswig <o PyHANDLE>|CreateSemaphore|Creates a Semaphore
// @rdesc The result is a handle to the created object
PyHANDLE CreateSemaphore(
    SECURITY_ATTRIBUTES *inNullSA, // lpSemaphoreAttributes,	// @pyparm object|securityAttributes||Placeholder for furture security object, or None
    LONG lInitialCount,	// @pyparm int|initialCount||initial count 
    LONG lMaximumCount,	// maximum count 
    TCHAR * INPUT_NULLOK // @pyparm <o PyIUnicode>|semaphoreName||semaphore-object name, or None
);
#endif // MS_WINCE

/*PyHANDLE CreateWaitableTimer(
    SECURITY_ATTRIBUTES *inNullSA, // lpTimerAttributes,	// pointer to security attributes
    BOOL bManualReset,	// @pyparm int|bManualReset||flag for manual reset state
    TCHAR * INPUT_NULLOK	// pointer to timer object name
);
*/

// GetOverlappedResult

%{
static BOOL MakeHandleList(PyObject *handleList, HANDLE **ppBuf, DWORD *pNumEntries)
{
	if (!PySequence_Check(handleList)) {
		PyErr_SetString(PyExc_TypeError, "Handles must be a list of integers");
		return FALSE;
	}
	DWORD numItems = (DWORD)PySequence_Length(handleList);
	HANDLE *pItems = (HANDLE *)malloc(sizeof(HANDLE) * numItems);
	if (pItems==NULL) {
		PyErr_SetString(PyExc_MemoryError,"Allocating array of handles");
		return FALSE;
	}
	for (DWORD i=0;i<numItems;i++) {
		PyObject *obItem = PySequence_GetItem(handleList, i);
		if (obItem==NULL) {
			free(pItems);
			return FALSE;
		}
		if (!PyWinObject_AsHANDLE(obItem,pItems+i)) {
			Py_DECREF(obItem);
			free(pItems);
			PyErr_SetString(PyExc_TypeError, "Handles must be a list of integers");
			return FALSE;
		}
		Py_DECREF(obItem);
	}
	*ppBuf = pItems;
	*pNumEntries = numItems;
	return TRUE;

}

%}

// @pyswig int|MsgWaitForMultipleObjects|Returns when a message arrives of an event is signalled
%name(MsgWaitForMultipleObjects) PyObject *MyMsgWaitForMultipleObjects(
    PyObject *obHandleList, // @pyparm [<o PyHANDLE>, ...]|handleList||A sequence of handles to wait on.
    BOOL bWaitAll, // @pyparm int|bWaitAll||If true, waits for all handles in the list.
    DWORD dwMilliseconds,	// @pyparm int|milliseconds||time-out interval in milliseconds 
    DWORD dwWakeMask 	// @pyparm int|wakeMask||type of input events to wait for.  One of the win32event.QS_ constants.
	// @ comm Note that if bWaitAll is TRUE, the function will return when there is input in the queue,
	// and all events are signalled.  This is rarely what you want!
	// If input is waiting, the result is win32event.WAIT_OBJECT_0+len(handles))
   );
%{
static PyObject * MyMsgWaitForMultipleObjects(
    PyObject *handleList,
    BOOL fWaitAll,	// wait for all or wait for one 
    DWORD dwMilliseconds,	// time-out interval in milliseconds 
    DWORD dwWakeMask )
{
	DWORD numItems;
	HANDLE *pItems;
	if (!MakeHandleList(handleList, &pItems, &numItems))
		return NULL;
	DWORD rc;
	Py_BEGIN_ALLOW_THREADS
	rc = MsgWaitForMultipleObjects(numItems, pItems, fWaitAll, dwMilliseconds, dwWakeMask);
	Py_END_ALLOW_THREADS
	PyObject *obrc;
	if (rc==(DWORD)0xFFFFFFFF)
		obrc = PyWin_SetAPIError("MsgWaitForMultipleObjects");
	else
		obrc = PyInt_FromLong(rc);
	free(pItems);
	return obrc;
}
%}

#ifndef MS_WINCE

// @pyswig int|MsgWaitForMultipleObjectsEx|Returns when a message arrives of an event is signalled
%name(MsgWaitForMultipleObjectsEx) PyObject *MyMsgWaitForMultipleObjectsEx(
    PyObject *obHandleList, // @pyparm [<o PyHANDLE>, ...]|handleList||A sequence of handles to wait on.
    BOOL fWaitAll,	// @pyparm int|fWaitAll||wait for all or wait for one 
    DWORD dwMilliseconds,	// @pyparm int|milliseconds||time-out interval in milliseconds 
    DWORD dwWakeMask, 	// @pyparm int|wakeMask||type of input events to wait for 
    DWORD dwFlags 	// @pyparm int|waitFlags||wait flags
   );

%{
static PyObject * MyMsgWaitForMultipleObjectsEx(
    PyObject *handleList,
    BOOL fWaitAll,	// wait for all or wait for one 
    DWORD dwMilliseconds,	// time-out interval in milliseconds 
    DWORD dwWakeMask,
    DWORD dwFlags 	// wait flags
 )
{
	DWORD numItems;
	HANDLE *pItems;
	if (!MakeHandleList(handleList, &pItems, &numItems))
		return NULL;
	DWORD rc;

	// Do a LoadLibrary, as the Ex version does not exist on NT3.x, Win95
	// @comm This method does not exist on NT3.5x or Win95.  If there
	// is an attempt to use it on these platforms, a COM error with
	// E_NOTIMPL will be raised.
	HMODULE hMod = GetModuleHandle("user32.dll");
	if (hMod==0) return PyWin_SetBasicCOMError(E_HANDLE);
	FARPROC fp = GetProcAddress(hMod, "MsgWaitForMultipleObjectsEx");
	if (fp==NULL) return PyWin_SetBasicCOMError(E_NOTIMPL);

	DWORD (*mypfn)(DWORD, LPHANDLE, DWORD, DWORD, DWORD);
	mypfn = (DWORD (*)(DWORD, LPHANDLE, DWORD, DWORD, DWORD))fp;
	Py_BEGIN_ALLOW_THREADS
	rc = (*mypfn)(numItems, pItems, dwMilliseconds, dwWakeMask, dwFlags);
	Py_END_ALLOW_THREADS
	PyObject *obrc;
	if (rc==(DWORD)0xFFFFFFFF)
		obrc = PyWin_SetAPIError("MsgWaitForMultipleObjectsEx");
	else
		obrc = PyInt_FromLong(rc);
	free(pItems);
	return obrc;
}
%}


// @pyswig <o PyHANDLE>|OpenEvent|Returns a handle of an existing named event object. 
PyHANDLE OpenEvent(
    DWORD dwDesiredAccess,	// @pyparm int|desiredAccess||access flag - one of <om win32event.EVENT_ALL_ACCESS>, <om win32event.EVENT_MODIFY_STATE>, or (NT only) <om win32event.SYNCHRONIZE>
    BOOL bInheritHandle,	// @pyparm int|bInheritHandle||inherit flag 
    TCHAR *lpName 	// @pyparm <o PyUnicode>|name||name of event to open.
   );

// @pyswig <o PyHANDLE>|OpenMutex|Returns a handle of an existing named mutex object. 
PyHANDLE OpenMutex(
    DWORD dwDesiredAccess,	// @pyparm int|desiredAccess||access flag 
    BOOL bInheritHandle,	// @pyparm int|bInheritHandle||inherit flag 
    TCHAR *lpName 	// @pyparm <o PyUnicode>|name||name of mutex to open.
   );

// @pyswig <o PyHANDLE>|OpenSemaphore|Returns a handle of an existing named semaphore object. 
PyHANDLE OpenSemaphore(
    DWORD dwDesiredAccess,	// @pyparm int|desiredAccess||access flag 
    BOOL bInheritHandle,	// @pyparm int|bInheritHandle||inherit flag 
    TCHAR *lpName 	// @pyparm <o PyUnicode>|name||name of semaphore to open.
   );

#endif /* MS_WINCE */

/*
PyHANDLE OpenWaitableTimer(
    DWORD dwDesiredAccess,	// access flag
    BOOL bInheritHandle,	// inherit flag
    TCHAR *lpTimerName	// pointer to timer object name
   );
*/ 

// @pyswig |PulseEvent|Provides a single operation that sets (to signaled) the state of the specified event object and then resets it (to nonsignaled) after releasing the appropriate number of waiting threads.
BOOLAPI PulseEvent(
    PyHANDLE hEvent 	// @pyparm <o PyHANDLE>|hEvent||handle of event object 
   );	

// @pyswig |ReleaseMutex|Releases a mutex.
BOOLAPI ReleaseMutex(
    PyHANDLE hMutex 	// @pyparm <o PyHANDLE>|hEvent||handle of mutex object  
   );

#ifndef MS_WINCE
// @pyswig int|ReleaseSemaphore|Releases a semaphore.
BOOLAPI ReleaseSemaphore(
    PyHANDLE hSemaphore,	// @pyparm <o PyHANDLE>|hEvent||handle of the semaphore object  
    LONG lReleaseCount,	// @pyparm int|lReleaseCount||amount to add to current count  
    long *OUTPUT 	// address of previous count 
// @rdesc The result is the previous count of the semaphore.
   );
#endif // MS_WINCE

// @pyswig |ResetEvent|Resets an event
BOOLAPI ResetEvent(
    PyHANDLE hEvent 	// @pyparm <o PyHANDLE>|hEvent||handle of event object 
   );	

// @pyswig |SetEvent|Sets an event
BOOLAPI SetEvent(
    PyHANDLE hEvent 	// @pyparm <o PyHANDLE>|hEvent||handle of event object 
   );	
 

// SetWaitableTimer	
/*
BOOLAPI SignalObjectAndWait(
    PyHANDLE hObjectToSignal,	// handle of object to signal
    PyHANDLE hObjectToWaitOn,	// handle of object to wait for
    DWORD dwMilliseconds,	// time-out interval in milliseconds
    BOOL bAlertable	// alertable flag
   );

*/
%{
static PyObject *MyWaitForMultipleObjects(
	PyObject *handleList,
	BOOL bWaitAll,	// wait flag 
	DWORD dwMilliseconds 	// time-out interval in milliseconds 
   )
{
	DWORD numItems;
	HANDLE *pItems;
	if (!MakeHandleList(handleList, &pItems, &numItems))
		return NULL;
	DWORD rc;
	Py_BEGIN_ALLOW_THREADS
	rc = WaitForMultipleObjects(numItems, pItems, bWaitAll, dwMilliseconds);
	Py_END_ALLOW_THREADS
	PyObject *obrc;
	if (rc==WAIT_FAILED)
		obrc = PyWin_SetAPIError("WaitForMultipleObjects");
	else
		obrc = PyInt_FromLong(rc);
	free(pItems);
	return obrc;
}

%}
// @pyswig int|WaitForMultipleObjects|Returns when an event is signalled
%name(WaitForMultipleObjects) PyObject *MyWaitForMultipleObjects(
    PyObject *handleList,  // @pyparm [<o PyHANDLE>, ...]|handleList||A sequence of handles to wait on.
    BOOL bWaitAll,	// @pyparm int|bWaitAll||wait flag 
    DWORD dwMilliseconds 	// @pyparm int|milliseconds||time-out interval in milliseconds 
   );	

#ifndef MS_WINCE
%{
static PyObject *MyWaitForMultipleObjectsEx(
	PyObject *handleList,
	BOOL bWaitAll,	// wait flag 
	DWORD dwMilliseconds, 	// time-out interval in milliseconds 
	BOOL bAlertable 	// alertable wait flag 
   )
{
	DWORD numItems;
	HANDLE *pItems;
	if (!MakeHandleList(handleList, &pItems, &numItems))
		return NULL;
	DWORD rc;
	Py_BEGIN_ALLOW_THREADS
	rc = WaitForMultipleObjectsEx(numItems, pItems, bWaitAll, dwMilliseconds,bAlertable);
	Py_END_ALLOW_THREADS
	PyObject *obrc;
	if (rc==WAIT_FAILED)
		obrc = PyWin_SetAPIError("WaitForMultipleObjectsEx");
	else
		obrc = PyInt_FromLong(rc);
	free(pItems);
	return obrc;
}
%}
// @pyswig int|WaitForMultipleObjectsEx|Returns when an event is signalled
%name(WaitForMultipleObjectsEx) PyObject *MyWaitForMultipleObjectsEx(
    PyObject *handleList, // @pyparm [<o PyHANDLE>, ...]|handleList||A sequence of handles to wait on.
    BOOL bWaitAll,	// @pyparm int|bWaitAll||wait flag 
    DWORD dwMilliseconds,	// @pyparm int|milliseconds||time-out interval in milliseconds 
    BOOL bAlertable 	// @pyparm int|bAlertable||alertable wait flag.
   );
#endif
%typedef DWORD DWORD_WAITAPI
%typemap(python,except) DWORD_WAITAPI {
      Py_BEGIN_ALLOW_THREADS
      $function
      Py_END_ALLOW_THREADS
      if ($source==WAIT_FAILED)  {
           $cleanup
           return PyWin_SetAPIError("$name");
      }
}

// @pyswig int|WaitForSingleObject|Returns when an event is signalled
DWORD_WAITAPI WaitForSingleObject(
    PyHANDLE hHandle,	// @pyparm <o PyHANDLE>|hHandle||handle of object to wait for 
    DWORD dwMilliseconds 	// @pyparm int|milliseconds||time-out interval in milliseconds  
   );

#ifndef MS_WINCE
// @pyswig int|WaitForSingleObjectEx|Returns when an event is signalled
DWORD_WAITAPI WaitForSingleObjectEx(
    PyHANDLE hHandle,	// @pyparm <o PyHANDLE>|hHandle||handle of object to wait for 
    DWORD dwMilliseconds, // @pyparm int|milliseconds||time-out interval in milliseconds  
    BOOL bAlertable // @pyparm int|bAlertable||alertable wait flag.
   );
#endif /* MS_WINCE */
