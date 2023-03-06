/* Вывести все заказы Баранова Павла (id заказа, какие книги, по какой цене и в каком количестве он заказал) в отсортированном по номеру заказа и названиям книг виде. */
 
SELECT buy.buy_id, title, price, buy_book.amount
FROM buy
    INNER JOIN client ON buy.client_id = client.client_id
    INNER JOIN buy_book ON buy_book.buy_id = buy.buy_id
    INNER JOIN book ON buy_book.book_id = book.book_id
WHERE name_client = "Баранов Павел"
ORDER BY buy.buy_id, title
 
/* Посчитать, сколько раз была заказана каждая книга, для книги вывести ее автора. 
Вывести фамилию и инициалы автора, название книги, последний столбец назвать "Количество". 
Результат отсортировать сначала по фамилиям авторов, а потом по названиям книг. */
  
SELECT name_author, title, COUNT(buy_book.amount) AS Количество
FROM author
	INNER JOIN book USING(author_id)
	LEFT JOIN buy_book USING(book_id)
GROUP BY book.title, name_author
ORDER BY name_author, title;
  
/* Вывести города, в которых живут клиенты, оформлявшие заказы в интернет-магазине. Указать количество заказов в каждый город ("Количество"). 
Информацию вывести по убыванию количества заказов, а затем в алфавитном порядке по названию городов.*/
   
SELECT name_city, COUNT(city.city_id) AS Количество
FROM city
    INNER JOIN client ON city.city_id = client.city_id
    INNER JOIN buy ON client.client_id = buy.client_id
GROUP BY name_city
ORDER BY Количество DESC, name_city
   
/* Вывести номера всех оплаченных заказов и даты, когда они были оплачены. */

SELECT buy_id, date_step_end
FROM buy_step 
WHERE buy_step.step_id = 1 AND date_step_end IS NOT NULL
	
/* Вывести информацию о каждом заказе: его номер, кто его сформировал (фамилия пользователя) и его стоимость, 
в отсортированном по номеру заказа виде. Последний столбец назвать "Стоимость". */

SELECT buy_book.buy_id, name_client, SUM(buy_book.amount * price) AS Стоимость
FROM client
    INNER JOIN buy ON client.client_id = buy.client_id
    INNER JOIN buy_book ON buy.buy_id = buy_book.buy_id
    INNER JOIN book ON book.book_id = buy_book.book_id
GROUP BY buy_id
ORDER BY buy_book.buy_id
	 
/* Вывести номера заказов и названия этапов, на которых они в данный момент находятся. 
Если заказ доставлен – информацию о нем не выводить. Информацию отсортировать по возрастанию buy_id. */

SELECT buy_id, name_step
FROM buy_step
    INNER JOIN step USING(step_id)
WHERE date_step_beg IS NOT NULL AND date_step_end IS NULL	  
	  
/* Для тех заказов, которые прошли этап транспортировки, вывести количество дней за которое заказ реально доставлен в город. 
А также, если заказ доставлен с опозданием, указать количество дней задержки, в противном случае вывести 0. 
В результат включить номер заказа (buy_id), а также вычисляемые столбцы Количество_дней и Опоздание. 
Информацию вывести в отсортированном по номеру заказа виде. */

SELECT buy_step.buy_id, DATEDIFF(date_step_end, date_step_beg) AS Количество_дней, 
        IF(DATEDIFF(date_step_end, date_step_beg)>days_delivery, 
           DATEDIFF(date_step_end, date_step_beg)-days_delivery,0) AS Опоздание
FROM city
    INNER JOIN client ON city.city_id = client.city_id
    INNER JOIN buy ON client.client_id = buy.client_id
    INNER JOIN buy_step ON buy.buy_id = buy_step.buy_id
WHERE buy_step.step_id = 3 AND date_step_end IS NOT NULL
ORDER BY buy_step.buy_id

/* Выбрать всех клиентов, которые заказывали книги Достоевского, информацию вывести в отсортированном по алфавиту виде. */

SELECT DISTINCT name_client
FROM client JOIN buy USING(client_id)
            JOIN buy_book USING(buy_id)
            JOIN book USING(book_id)
            JOIN author USING(author_id)
WHERE author.name_author LIKE 'Достоевский Ф.М.'
ORDER BY name_client;
		
/* Вывести жанр, в котором было заказано больше всего экземпляров книг, указать это количество ("Количество"). */

SELECT name_genre, Количество
FROM
    (SELECT name_genre, sum(amount_1) as Количество
        FROM (SELECT book_id, SUM(amount) AS amount_1
        FROM buy_book
        GROUP BY book_id) AS temp
        INNER JOIN book ON temp.book_id = book.book_id
        INNER JOIN genre ON book.genre_id = genre.genre_id
        GROUP BY name_genre) as k
        where k.Количество IN (SELECT MAX(t.Количество) as n
                               FROM( SELECT name_genre, sum(amount_1) AS Количество
                               FROM (SELECT book_id, SUM(amount) AS amount_1
                               FROM buy_book
                               GROUP BY book_id) AS temp
                               INNER JOIN book ON temp.book_id = book.book_id
                               INNER JOIN genre ON book.genre_id = genre.genre_id
                               GROUP BY name_genre) as t);

/* Сравнить ежемесячную выручку от продажи книг за текущий и предыдущий годы. 
Для этого вывести год, месяц, сумму выручки в отсортированном сначала по возрастанию месяцев, затем по возрастанию лет виде. 
Название столбцов: Год, Месяц, Сумма. */

SELECT YEAR(date_payment) AS Год, MONTHNAME(date_payment)AS Месяц, SUM(price*amount) AS Сумма
FROM buy_archive
GROUP BY Год, Месяц

UNION ALL

SELECT YEAR(date_step_end) AS Год, MONTHNAME(date_step_end)AS Месяц,  SUM(price * buy_book.amount) AS Сумма
FROM buy_step
    INNER JOIN buy_book USING(buy_id)
    INNER JOIN book USING(book_id)
WHERE date_step_end IS NOT NULL AND step_id = 1
GROUP BY Год, Месяц
ORDER BY Месяц ASC, Год ASC;

/* Для каждой отдельной книги необходимо вывести информацию о количестве проданных экземпляров и их стоимости за 2020 и 2019 год . 
Вычисляемые столбцы назвать Количество и Сумма. Информацию отсортировать по убыванию стоимости. */

SELECT title, sum(Количесвто) as Количество, sum(Сумма) as Сумма
FROM
(select title, sum(buy_archive.amount) as Количесвто, sum(buy_archive.price*buy_archive.amount) as Сумма from buy_archive
JOIN book USING(book_id)
group by title
union all
select title, sum(buy_book.amount) as Количество, sum(price*buy_book.amount) as Сумма from book
JOIN buy_book using (book_id)
JOIN buy_step using (buy_id)
JOIN step using (step_id)
where step.name_step = "Оплата" and buy_step.date_step_end is not null
group by title) as query_in
group by title
order by Сумма desc
			