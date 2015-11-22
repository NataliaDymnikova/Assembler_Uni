// FourierTransform.cpp : Defines the entry point for the application.
//

#include "stdafx.h"
#include "FourierTransform.h"

#define MAX_LOADSTRING 100

// Global Variables:
HINSTANCE hInst;								// current instance
TCHAR szTitle[MAX_LOADSTRING];					// The title bar text
TCHAR szWindowClass[MAX_LOADSTRING];			// the main window class name

// Forward declarations of functions included in this code module:
ATOM				MyRegisterClass(HINSTANCE hInstance);
BOOL				InitInstance(HINSTANCE, int);
LRESULT CALLBACK	WndProc(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK	About(HWND, UINT, WPARAM, LPARAM);


// Функция вычисления спектра (преобразование Фурье). Реализована в Labn_Name_xx.asm
extern "C" void CalculateSpectrum(spectrum_type* Spectrum, signal_type* Signal);
// Функция вычисления сигнала по спектру (обратное преобразование Фурье)
extern "C" void RecoverSignal(signal_type* Signal, spectrum_type* Spectrum);

// Глобальные переменные для отображения сигналов
SignalView sig ;
SpectrumView sp_re, sp_im(RGB(0xFF,0,0x40));
spectrum_type Spectrum[FT_SIGNAL_SIZE*2];
signal_type Signal_source[FT_SIGNAL_SIZE];
signal_type Signal_recovered[FT_SIGNAL_SIZE];
__int64 DFT_time = 0 ;
__int64 IDFT_time = 0;

int APIENTRY _tWinMain(_In_ HINSTANCE hInstance,
                     _In_opt_ HINSTANCE hPrevInstance,
                     _In_ LPTSTR    lpCmdLine,
                     _In_ int       nCmdShow)
{
	UNREFERENCED_PARAMETER(hPrevInstance);
	UNREFERENCED_PARAMETER(lpCmdLine);

 	// TODO: Place code here.
	MSG msg;
	HACCEL hAccelTable;

	// Initialize global strings
	LoadString(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
	LoadString(hInstance, IDC_FOURIERTRANSFORM, szWindowClass, MAX_LOADSTRING);
	MyRegisterClass(hInstance);

	// Perform application initialization:
	if (!InitInstance (hInstance, nCmdShow))
	{
		return FALSE;
	}

	hAccelTable = LoadAccelerators(hInstance, MAKEINTRESOURCE(IDC_FOURIERTRANSFORM));

	// Main message loop:
	while (GetMessage(&msg, NULL, 0, 0))
	{
		if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg))
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
	}

	return (int) msg.wParam;
}



//
//  FUNCTION: MyRegisterClass()
//
//  PURPOSE: Registers the window class.
//
ATOM MyRegisterClass(HINSTANCE hInstance)
{
	WNDCLASSEX wcex;

	wcex.cbSize = sizeof(WNDCLASSEX);

	wcex.style			= CS_HREDRAW | CS_VREDRAW;
	wcex.lpfnWndProc	= WndProc;
	wcex.cbClsExtra		= 0;
	wcex.cbWndExtra		= 0;
	wcex.hInstance		= hInstance;
	wcex.hIcon			= LoadIcon(hInstance, MAKEINTRESOURCE(IDI_ICON_FROG));
	wcex.hCursor		= LoadCursor(NULL, IDC_ARROW);
	wcex.hbrBackground	= (HBRUSH)(COLOR_WINDOW+1);
	wcex.lpszMenuName	= MAKEINTRESOURCE(IDC_FOURIERTRANSFORM);
	wcex.lpszClassName	= szWindowClass;
	wcex.hIconSm		= LoadIcon(wcex.hInstance, MAKEINTRESOURCE(IDI_ICON_FROG));

	return RegisterClassEx(&wcex);
}

//
//   FUNCTION: InitInstance(HINSTANCE, int)
//
//   PURPOSE: Saves instance handle and creates main window
//
//   COMMENTS:
//
//        In this function, we save the instance handle in a global variable and
//        create and display the main program window.
//
BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
   HWND hWnd;

   hInst = hInstance; // Store instance handle in our global variable

   hWnd = CreateWindow(szWindowClass, szTitle, WS_OVERLAPPEDWINDOW,
      CW_USEDEFAULT, 0, CW_USEDEFAULT, 0, NULL, NULL, hInstance, NULL);

   if (!hWnd)
   {
      return FALSE;
   }

   ShowWindow(hWnd, nCmdShow);
   UpdateWindow(hWnd);

   return TRUE;
}

//
//  FUNCTION: WndProc(HWND, UINT, WPARAM, LPARAM)
//
//  PURPOSE:  Processes messages for the main window.
//
//  WM_COMMAND	- process the application menu
//  WM_PAINT	- Paint the main window
//  WM_DESTROY	- post a quit message and return
//
//
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	int wmId, wmEvent;
	PAINTSTRUCT ps;
	HDC hdc;
	RECT  rc;
	long width, hight;
	RECT rc_signal, rc_spectrum_re, rc_spectrum_im;
	SIZE text_size;
	TCHAR CalcTime_txt[128];

	switch (message)
	{
	case WM_COMMAND:
		wmId    = LOWORD(wParam);
		wmEvent = HIWORD(wParam);
		// Parse the menu selections:
		switch (wmId)
		{
			// Выбор исходного сигнала
		case ID_GENERATESIGNAL_SINE:
			sig.SetSource(SV_SIN);
			sp_re.Clear();
			sp_im.Clear();
			DFT_time = IDFT_time = 0;
			InvalidateRect(hWnd, NULL, TRUE);
			break;
		case ID_GENERATESIGNAL_COSINE:
			sig.SetSource(SV_COS);
			sp_re.Clear();
			sp_im.Clear();
			DFT_time = IDFT_time = 0;
			InvalidateRect(hWnd, NULL, TRUE);
			break;
		case ID_GENERATESIGNAL_SAW:
			sig.SetSource(SV_SAW);
			sp_re.Clear();
			sp_im.Clear();
			DFT_time = IDFT_time = 0;
			InvalidateRect(hWnd, NULL, TRUE);
			break;
		case ID_GENERATESIGNAL_SQUARE:
			sig.SetSource(SV_SQUARE);
			sp_re.Clear();
			sp_im.Clear();
			DFT_time = IDFT_time = 0;
			InvalidateRect(hWnd, NULL, TRUE);
			break;
			// Вычисление спектра
		case ID_FILE_CALCULATESPECTRUM:
			sig.GetSignalSample(Signal_source);
			DFT_time = __rdtsc();
			CalculateSpectrum(Spectrum, Signal_source);
			DFT_time = __rdtsc() - DFT_time;
			sp_re.SetSpectrum(Spectrum);
			sp_im.SetSpectrum(Spectrum + FT_SIGNAL_SIZE);
			InvalidateRect(hWnd, NULL, TRUE);
			break;
			// Восстановление сигнала по спектру
		case ID_FILE_RECOVERSIGNAL:
			IDFT_time = __rdtsc();
			RecoverSignal(Signal_recovered, Spectrum);
			IDFT_time = __rdtsc() - IDFT_time;
			sig.SetRecovered(Signal_recovered);
			InvalidateRect(hWnd, NULL, TRUE);
			break;
		case IDM_ABOUT:
			DialogBox(hInst, MAKEINTRESOURCE(IDD_ABOUTBOX), hWnd, About);
			break;
		case IDM_EXIT:
			DestroyWindow(hWnd);
			break;
		default:
			return DefWindowProc(hWnd, message, wParam, lParam);
		}
		break;
	case WM_PAINT:
		hdc = BeginPaint(hWnd, &ps);
		GetClientRect(hWnd, &rc);
		// Вычисление высоты строки
		GetTextExtentPoint32(hdc, _T("Re"), _tcslen(_T("Re")), &text_size);

		// Вычисление области рисования графика сигнала
		width = (rc.right - rc.left) * 2/3;
		hight = rc.bottom - rc.top - text_size.cy*2;		
		rc_signal.left = rc.left + width / 20;
		rc_signal.right = rc.left + width - width/20;
		rc_signal.top = rc.top + hight / 20 + text_size.cy ;
		rc_signal.bottom = rc.bottom - hight / 20 - text_size.cy ;

		// Вычисление области рисования действительной части спектра
		width = (rc.right - rc.left)/3;
		hight = (rc.bottom - rc.top)/2 - text_size.cy*2;		
		rc_spectrum_re.left = rc.right - width + width / 20;
		rc_spectrum_re.right = rc.right - width / 20;
		rc_spectrum_re.top = rc.top + hight / 20 + text_size.cy;
		rc_spectrum_re.bottom = rc.top + hight - hight / 20 - text_size.cy ;

		// Вычисление области рисования мнимой части спектра
		width = (rc.right - rc.left)/3;
		hight = (rc.bottom - rc.top) / 2 - text_size.cy * 2;
		rc_spectrum_im.left = rc.right - width + width / 20;
		rc_spectrum_im.right = rc.right - width / 20;
		rc_spectrum_im.top = rc.bottom - hight + hight / 20 + text_size.cy ;
		rc_spectrum_im.bottom = rc.bottom - hight / 20 - text_size.cy ;

		// Отображение сигнала и спектра (действительной и мнимой частей)
		sig.View(hdc, rc_signal);
		sp_re.View(hdc, rc_spectrum_re);
		sp_im.View(hdc, rc_spectrum_im);

		// Подписи графиков
		TextOut(hdc, rc_signal.left, rc.top + 10, _T("Сигнал"), 6);
		TextOut(hdc, rc_spectrum_re.left, rc.top + 5, _T("Спектр"), 6);
		if (0 != IDFT_time) {
			_stprintf_s(CalcTime_txt, 128, _T("Время вычисления -- %I64d"), IDFT_time);
			TextOut(hdc, rc_signal.left, rc.bottom - text_size.cy - 5, CalcTime_txt, _tcslen(CalcTime_txt));
		}
		if (0 != DFT_time) {
			_stprintf_s(CalcTime_txt, 128, _T("Время вычисления -- %I64d"), DFT_time);
			TextOut(hdc, rc_spectrum_im.left, rc.bottom - text_size.cy - 5, CalcTime_txt, _tcslen(CalcTime_txt));
		}
		TextOut(hdc, rc_spectrum_re.left - text_size.cx - 2, rc_spectrum_re.top, _T("Re"), _tcslen(_T("Re")));
		TextOut(hdc, rc_spectrum_im.left - text_size.cx - 2, rc_spectrum_im.top, _T("Im"), _tcslen(_T("Im")));

		ValidateRect(hWnd, NULL);
		EndPaint(hWnd, &ps);
		break;
	case WM_DESTROY:
		PostQuitMessage(0);
		break;
	default:
		return DefWindowProc(hWnd, message, wParam, lParam);
	}
	return 0;
}

// Message handler for about box.
INT_PTR CALLBACK About(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);
	switch (message)
	{
	case WM_INITDIALOG:
		return (INT_PTR)TRUE;

	case WM_COMMAND:
		if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)
		{
			EndDialog(hDlg, LOWORD(wParam));
			return (INT_PTR)TRUE;
		}
		break;
	}
	return (INT_PTR)FALSE;
}
