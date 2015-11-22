/* ------------------------------------------------------------------------------------------------------------------- *\
Файл SignalView.h

Материалы к курсу "Программирование на языке ассемблера"

Содержит декларации классов, предназначенных для отображения периодических сигналов и спектра.

Требует включения (в stdafx.h)

(c) Федоров А.Р., 2014
Разрешено свободное копирование и любое использование в той мере, в которой
это не нарушает прав других правообладателей
\* ------------------------------------------------------------------------------------------------------------------- */
#pragma once
// Константы настройки на вариант работы
#include "Tuning.h"

// Предопределенные типы исходных сигналов для отображения
#define SV_NONE (-1)		// Никакого сигнала
#define SV_SIN 1		// Синусоида
#define SV_COS 2		// Косинусоида
#define SV_SQUARE 3		// Прямоугольный сигнал
#define SV_SAW	4		// Пилообразный

// Амплитуда сигнала
#define AMPLITUDE 100.

class SignalView
{
private:
	// Исходный сигнал
	int		_type;			// Вид линии
	COLORREF _color_src;	// Цвет линии

	// Восстановленный сигнал
	double	*_recovered;		// Набор значений (FT_SIGNAL_SIZE)
	COLORREF _color_rec;		// Цвет точек
public:
	SignalView(COLORREF color_src = RGB(0, 0, 0xFF), COLORREF color_rec = RGB(0xF0, 0, 0x40)) :
		_color_src(color_src), _type(-1), _color_rec(color_rec), _recovered(NULL) 	{}
	~SignalView() { if (NULL != _recovered) delete _recovered; }
	// Функция отображения сигнала в заданной области
	void View(HDC hDC, RECT Area) {
	// hDC   - контекст устройства для отображения
	// Area  - прямоугольник в контексте устройства, область отображения графика
		HPEN hpen;
		HGDIOBJ oldpen;
		double f, x;
		long i;
		long width = Area.right - Area.left;
		double amplitude = (Area.bottom-Area.top) / 2;

		// Точка (0,0)
		POINT zz;
		zz.x = Area.left;
		zz.y = (Area.top + Area.bottom) / 2;
		// Вертикальная ось координат
		MoveToEx(hDC, zz.x, Area.top, NULL);
		LineTo(hDC, zz.x, Area.bottom);
		// Горизонтальная ось координат
		MoveToEx(hDC, zz.x, zz.y, NULL);
		LineTo(hDC, Area.right, zz.y);

		// Рисование исходного сигнала 
		hpen = CreatePen(PS_SOLID, 1, _color_src);
		oldpen = SelectObject(hDC, hpen);
		switch (_type)
		{
		case SV_NONE:
			break;
		case SV_SIN:
			MoveToEx(hDC, zz.x, zz.y, NULL);
			for (i = 0; i < width; i++)
			{
				x = double(i) * 2. * M_PI / double(width);
				f = amplitude * sin(x);
				LineTo(hDC, zz.x + i, zz.y - int(f));
			}
			LineTo(hDC, zz.x + width, zz.y );
			break;
		case SV_COS:
			MoveToEx(hDC, zz.x, Area.top, NULL);
			for (i = 0; i < width; i++)
			{
				x = double(i) * 2. * M_PI / double(width);
				f = amplitude * cos(x);
				LineTo(hDC, zz.x + i, zz.y - int(f));
			}
			LineTo(hDC, zz.x + width, Area.top );
			break;
		case SV_SQUARE:
			MoveToEx(hDC, zz.x, Area.top, NULL);
			LineTo(hDC, (Area.left + Area.right) / 2, Area.top);
			LineTo(hDC, (Area.left + Area.right) / 2, Area.bottom);
			LineTo(hDC, Area.right, Area.bottom);
			LineTo(hDC, Area.right, Area.top);
			break;
		case SV_SAW:
			MoveToEx(hDC, zz.x, zz.y, NULL);
			LineTo(hDC, (Area.left + Area.right) / 2, Area.top);
			LineTo(hDC, (Area.left + Area.right) / 2, Area.bottom);
			LineTo(hDC, Area.right, zz.y);
			break;

		default:
			break;
		}
		DeleteObject(hpen);

		// Рисование восстановленного сигнала
		if (NULL != _recovered) {
			hpen = CreatePen(PS_SOLID, 1, _color_rec);
			SelectObject(hDC, hpen);

			double step = double(width) / double(FT_SIGNAL_SIZE);
			POINT pnt;
			for (i = 0; i < FT_SIGNAL_SIZE; i++) {
				pnt.x = zz.x + long(round(double(i) * step));
				pnt.y = zz.y - long(round(_recovered[i] / AMPLITUDE*amplitude));
				Ellipse(hDC, pnt.x - 3, pnt.y - 3, pnt.x + 3, pnt.y + 3);
			}
			pnt.x = Area.right;
			pnt.y = zz.y - long(round(_recovered[0] / AMPLITUDE*amplitude));
			Ellipse(hDC, pnt.x - 3, pnt.y - 3, pnt.x + 3, pnt.y + 3);

			DeleteObject(hpen);
		}
		SelectObject(hDC, oldpen);	
	}

	// Функция установки в отображаемую область исходного сигнала заданной формы
	void SetSource(int Type) {
		_type = Type;
		if (NULL != _recovered)
			delete _recovered;
		_recovered = NULL;
	}

	// Функция установки в отображаемую область восстановленного сигнала по отсчетам
	void SetRecovered(signal_type* Recovered)
	{
		if (_type != SV_NONE){
			if (NULL == _recovered )
				_recovered = new double[FT_SIGNAL_SIZE];
			for (int i = 0; i < FT_SIGNAL_SIZE; i++)
				_recovered[i] = double(Recovered[i]);
		}
	}

	void GetSignalSample(signal_type* Sample)
	{
		double x, f;
		switch (_type){
		case SV_SIN:
			for (int i = 0; i < FT_SIGNAL_SIZE; i++){
				x = double(i) * 2. * M_PI / double(FT_SIGNAL_SIZE);
				f = AMPLITUDE * sin(x);
				Sample[i] = signal_type(f);
			}
			break;
		case SV_COS:
			for (int i = 0; i < FT_SIGNAL_SIZE; i++){
				x = double(i) * 2. * M_PI / double(FT_SIGNAL_SIZE);
				f = AMPLITUDE * cos(x);
				Sample[i] = signal_type(f);
			}
			break;
		case SV_SQUARE:
			for (int i = 0; i < FT_SIGNAL_SIZE / 2; i++)
				Sample[i] = signal_type(AMPLITUDE);
			for (int i = FT_SIGNAL_SIZE / 2; i < FT_SIGNAL_SIZE ; i++)
				Sample[i] = signal_type(-AMPLITUDE);
			break;
		case SV_SAW:
			for (int i = 0; i < FT_SIGNAL_SIZE / 2; i++)
				Sample[i] = signal_type(double(i)*double(AMPLITUDE)*2. / double(FT_SIGNAL_SIZE));
			for (int i = FT_SIGNAL_SIZE / 2; i < FT_SIGNAL_SIZE ; i++)
				Sample[i] = signal_type(double(i)*double(AMPLITUDE)*2. / double(FT_SIGNAL_SIZE) - double(AMPLITUDE)*2.);
			break;
		default:
			break;
		}
	}
};

class SpectrumView{
private:
	COLORREF _color;	// Цвет графика
	double* _spectrum;	// Массив значений
public:
	SpectrumView(COLORREF color = RGB(0,0x80,0x20)) : _color(color), _spectrum(NULL) {}
	~SpectrumView() { if (NULL != _spectrum) delete _spectrum; }
	// Функция установки спектра в отображаемую область по отсчетам
	void SetSpectrum(spectrum_type* Spectrum) {
		if (NULL == _spectrum)
			_spectrum = new double[FT_SIGNAL_SIZE];
		for (int i = 0; i < FT_SIGNAL_SIZE; i++)
			_spectrum[i] = double(Spectrum[i]);
	}
	void View(HDC hDC, RECT Area) {
		// hDC   - контекст устройства для отображения
		// Area  - прямоугольник в контексте устройства, область отображения графика
		HPEN hpen;
		HGDIOBJ oldpen;
		// Точка (0,0)
		POINT zz;
		zz.x = Area.left;
		zz.y = (Area.top + Area.bottom) / 2;
		// Ширина и высота
		int width = Area.right - Area.left;
		int hight = Area.bottom - Area.top;
		// Вертикальная ось координат
		MoveToEx(hDC, zz.x, Area.top, NULL);
		LineTo(hDC, zz.x, Area.bottom);
		// Горизонтальная ось координат
		MoveToEx(hDC, zz.x, zz.y, NULL);
		LineTo(hDC, Area.right, zz.y);

		if (NULL != _spectrum){
			// Множитель амплитуды
			double a_min = DBL_MAX;
			double a_max = DBL_MIN;
			for (int i = 0; i < FT_SIGNAL_SIZE; i++)
			{
				a_max = max(a_max, _spectrum[i]);
				a_min = min(a_min, _spectrum[i]);
			}
			if (a_max < 0)a_max = -a_max;
			if (a_min < 0)a_min = -a_min;

			double amplitude = double(hight) / max(a_max, a_min) / 2.;

			hpen = CreatePen(PS_SOLID, 1, _color);
			oldpen = SelectObject(hDC, hpen);
			double step = double(width) / double(FT_SIGNAL_SIZE);
			POINT pnt;
			for (int i = 0; i < FT_SIGNAL_SIZE; i++) {
				pnt.x = zz.x + long(round(double(i) * step));
				pnt.y = zz.y - long(round(_spectrum[i] * amplitude));
				MoveToEx(hDC, pnt.x, pnt.y, NULL);
				LineTo(hDC, pnt.x, zz.y);
				Ellipse(hDC, pnt.x - 3, pnt.y - 3, pnt.x + 3, pnt.y + 3);
			}
			DeleteObject(hpen);
			SelectObject(hDC, oldpen);
		}
	}
	void Clear(void) {
		if (_spectrum != NULL){
			delete _spectrum;
			_spectrum = NULL;
		}
	}
};