////////////////////////////////////////////////////////////////////////////////
// ЗапросHTTP: обертка для работы с HTTPЗапрос
//  
////////////////////////////////////////////////////////////////////////////////

#Область ПрограммныйИнтерфейс

// Выполняет HTTP запрос, обрабатывает ошибочные ситуации, возвращает ответ, признак успешного выполнения и описание ошибки
//
// Параметры:
//  ЗащищенноеСоединение  - Булево - при запросе используется защищенное соединение
//  АдресСервиса  - Строка - адрес сервиса, который предоставляет API
//  ПараметрыURI  - Строка - параметры, которые передаются через URI, а не через тело (все, что передается после адреса сервиса)
//  МассивЗаголовки  - Массив - массив, содержит структуры со свойствами
//									* Заголовок - строка
//									* Значение - строка
//  ПараметрыТело  - Строка - параметры запроса, которые передаются в теле запроса
//  ВидЗапроса  - Строка - GET, POST, PUT, PUTCH, DELETE - определяет метод запроса, если метод не задан или задан неверно, то вызыватся GET
//	СжиматьОтвет - Булово, если веб-сервер может отдавать даныне в формат zip, то к запросу будет добавлен соответствующий заголовок "Accept-Encoding"
//	ПолучитьТелоКак - Строка, три возможных значения - "Строка", "ДвоичныеДанные", "Файл", по умолчанию - "Строка"
//	КодировкаТекста - КодировкаТекста или строка - для получения тела как строки, по умолчанюи UTF8
//
// Возвращаемое значение:
//   Структура   - структура со свойствами
//					* Заголовки - Соотствие, HTTP-заголовки ответа сервера в виде соответствия: "Название заголовка" - "Значение".
//					* ТелоОтвета - Строка, двоичные данные
//					* КодСостояния - код ответа HTTP или -1, если ответ не пришел
//					* ЗапросОбработанУспешно - Булево, если запрос обработан успешно (код состояния 2хх или 404)
//					* ОписаниеОшибки - строка, содержащая код состояния и описание ошибки
//
Функция ПолучитьОтветНаЗапрос(Знач ЗащищенноеСоединение, 
								Знач АдресСервиса, 
								Знач ПараметрыURI = "", 
								Знач МассивЗаголовки = Неопределено, 
								Знач ПараметрыТело = "", 
								ВидЗапроса = "GET", 
								СжиматьОтвет = Ложь, 
								ПолучитьТелоКак = "Строка", 
								КодировкаТекста = "UTF-8") Экспорт
	
	СтруктураОтвета = Новый Структура;
	СтруктураОтвета.Вставить("Заголовки", 				Новый Соответствие); 
	СтруктураОтвета.Вставить("ТелоОтвета", 				"");
	СтруктураОтвета.Вставить("КодСостояния", 			-1);
	СтруктураОтвета.Вставить("ЗапросОбработанУспешно", 	Ложь);
	СтруктураОтвета.Вставить("ОписаниеОшибки", 			"Запрос не выполнен");
	
	Если ВидЗапроса = "PUT" И ПараметрыТело = "" Тогда
		ПараметрыТело = "PUT";
	КонецЕсли;
	
	Если СжиматьОтвет Тогда 
		
		Если МассивЗаголовки = Неопределено Тогда
			
			МассивЗаголовки = Новый Массив;
			
		КонецЕсли;
		
		ЗаголовокHTTP = Новый Структура;
		ЗаголовокHTTP.Вставить("Заголовок", "Accept-Encoding");
		ЗаголовокHTTP.Вставить("Значение", "zip");
		МассивЗаголовки.Добавить(ЗаголовокHTTP);
		
	КонецЕсли;
		
	HTTPЗапрос = Новый HTTPЗапрос(ПараметрыURI);
	
	Если ТипЗнч(МассивЗаголовки) = Тип("Массив") Тогда
		
		Для каждого ЗаголовокHTTP Из МассивЗаголовки Цикл
		
			HTTPЗапрос.Заголовки.Вставить(ЗаголовокHTTP.Заголовок, ЗаголовокHTTP.Значение);
		
		КонецЦикла;
		
	КонецЕсли;
	
	Если ЗначениеЗаполнено(ПараметрыТело) Тогда
		
		HTTPЗапрос.УстановитьТелоИзСтроки(ПараметрыТело);
		
	КонецЕсли;
	
	HTTPСоединение = Новый HTTPСоединение(АдресСервиса, , , , , , ?(ЗащищенноеСоединение, Новый ЗащищенноеСоединениеOpenSSL, Неопределено));
	
	Попытка
		
		Если ВРег(ВидЗапроса) = "POST" Тогда
		
			Ответ = HTTPСоединение.ОтправитьДляОбработки(HTTPЗапрос);
			
		ИначеЕсли ВРег(ВидЗапроса) = "DELETE" Тогда
		
			Ответ = HTTPСоединение.Удалить(HTTPЗапрос);
			
		ИначеЕсли ВРег(ВидЗапроса) = "PUT" Тогда
		
			Ответ = HTTPСоединение.Записать(HTTPЗапрос);
			
		ИначеЕсли ВРег(ВидЗапроса) = "PATCH" Тогда
		
			Ответ = HTTPСоединение.Изменить(HTTPЗапрос);
			
		Иначе //всегда GET
		
			Ответ = HTTPСоединение.Получить(HTTPЗапрос);
			
		КонецЕсли;
		
	Исключение
		
		Ответ = Неопределено;
		
		СтруктураОтвета.ОписаниеОшибки = ОписаниеОшибки();
		
	КонецПопытки;
	
	Если Ответ <> Неопределено Тогда
		
		Если ЗапросОбработанУспешно(Ответ) Тогда
			
			Попытка
				
				Если ПолучитьТелоКак = "Строка" Тогда
					
					Если СжиматьОтвет Тогда
						
						ТелоОтвета = РаспаковатьСтрокуОтвета(Ответ.ПолучитьТелоКакДвоичныеДанные(), КодировкаТекста);
						
					Иначе
					
						ТелоОтвета = Ответ.ПолучитьТелоКакСтроку(КодировкаТекста);
						
					КонецЕсли;
					
				ИначеЕсли ПолучитьТелоКак = "ДвоичныеДанные" Тогда
					
					ТелоОтвета = Ответ.ПолучитьТелоКакДвоичныеДанные();
					
				ИначеЕсли ПолучитьТелоКак = "Файл" Тогда
					
					ТелоОтвета = Ответ.ПолучитьИмяФайлаТела();
					
				Иначе
					
					ТелоОтвета = Ответ.ПолучитьТелоКакСтроку();
					
				КонецЕсли;

				СтруктураОтвета.Заголовки = Ответ.Заголовки;
				СтруктураОтвета.КодСостояния = Ответ.КодСостояния;
				СтруктураОтвета.ТелоОтвета = ТелоОтвета;
				СтруктураОтвета.ЗапросОбработанУспешно = Истина;
				
			Исключение
				
				СтруктураОтвета.ОписаниеОшибки = "Не удалось обработать тело ответа по причине: " + Символы.ПС + ОписаниеОшибки();
				
			КонецПопытки;
			
		Иначе
			
			СтруктураОтвета.ОписаниеОшибки = ТекстСообщенияОбОшибке(Ответ);
			
		КонецЕсли;
		
	КонецЕсли;
	
	Если СтруктураОтвета.ЗапросОбработанУспешно Тогда
		
		СтруктураОтвета.ОписаниеОшибки = "";
		
	КонецЕсли;
	
	Возврат СтруктураОтвета;
	
КонецФункции

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Функция ТекстСообщенияОбОшибке(Знач Ответ) Экспорт
	
	Если ТипЗнч(Ответ) = Тип("HTTPОтвет") Тогда
		
		Возврат "Ошибка: " + Строка(Ответ.КодСостояния) + Символы.ПС + Ответ.ПолучитьТелоКакСтроку(КодировкаТекста.UTF8);
		
	Иначе
		
		Возврат "Ошибка: не получен ответ от веб-сервиса";
		
	КонецЕсли;
	
КонецФункции

// Определяет успешность выполнения запроса (код ответа от 200 до 299)
//
// Параметры:
//  Ответ  - ОтветHTTP
//
// Возвращаемое значение:
//   Булево
//
Функция ЗапросОбработанУспешно(Знач Ответ) Экспорт
	
	Если ТипЗнч(Ответ) = Тип("HTTPОтвет") Тогда
	
		Если ((Ответ.КодСостояния > 199) И (Ответ.КодСостояния < 300)) Тогда
			
			Возврат Истина;
			
		Иначе
			
			Возврат Ложь;
			
		КонецЕсли;
		
	Иначе
		
		Возврат Ложь;
		
	КонецЕсли;
	
КонецФункции

// Распаковывает zip, полученный в виде двоичных данных и возвращает строку
//
// Параметры:
//  ЗапакованныйОтвет - ДвоичныеДанные - строка, упакованная в zip
// 
// Возвращаемое значение:
//   - Строка
//
Функция РаспаковатьСтрокуОтвета(ЗапакованныйОтвет, КодировкаТекста = "UTF-8") Экспорт
	
	Если ЗапакованныйОтвет.Размер() = 0 Тогда
		
		Возврат "";
		
	КонецЕсли;
	
	МассивВременныхФайлов = Новый Массив;

	ИмяФайла = ПолучитьИмяВременногоФайла("zip");
	
	МассивВременныхФайлов.Добавить(ИмяФайла);
	
	ЗапакованныйОтвет.Записать(ИмяФайла);
	
	ZIP = Новый ЧтениеZipФайла(ИмяФайла);                 
	
	Для Каждого ИнформацияОФайлеИзАрхива Из ZIP.Элементы Цикл
		
		Если ПустаяСтрока(ИнформацияОФайлеИзАрхива.Имя) Тогда
			Продолжить;
		КонецЕсли;
		
		ZIP.Извлечь(ИнформацияОФайлеИзАрхива, КаталогВременныхФайлов(), РежимВосстановленияПутейФайловZIP.НеВосстанавливать);
		
		ПутьКРаспакованномуФайлу = КаталогВременныхФайлов() + ИнформацияОФайлеИзАрхива.Имя;
		МассивВременныхФайлов.Добавить(ПутьКРаспакованномуФайлу);
		
		ТекстовыйДок = Новый ТекстовыйДокумент;
		ТекстовыйДок.Прочитать(ПутьКРаспакованномуФайлу, КодировкаТекста);
		ОтветСтрокой = ТекстовыйДок.ПолучитьТекст();
		
	КонецЦикла;
	
	ZIP.Закрыть();
	
	Для каждого ВременныйФайл Из МассивВременныхФайлов Цикл
	
		УдалитьФайлы(ВременныйФайл);
	
	КонецЦикла;
	
	Возврат ОтветСтрокой;

КонецФункции // РаспаковатьСтрокуОтвета()

#КонецОбласти