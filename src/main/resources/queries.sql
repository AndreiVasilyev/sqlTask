--1.	Вывести к каждому самолету класс обслуживания и количество мест этого класса
select aircraft_code, fare_conditions, count(seat_no) as sets_count
from seats
group by aircraft_code, fare_conditions
order by aircraft_code;
--2.	Найти 3 самых вместительных самолета (модель + кол-во мест)
select ac.model, count(seat_no) as sets_count
from seats as s join aircrafts_data as ac using(aircraft_code)
group by ac.model
order by sets_count desc
    limit 3;
--3.	Найти все рейсы, которые задерживались более 2 часов
select flight_no, EXTRACT(HOUR from actual_arrival-scheduled_arrival) as delay from flights
where EXTRACT(HOUR from actual_arrival-scheduled_arrival)>2;
--4.	Найти последние 10 билетов, купленные в бизнес-классе (fare_conditions = 'Business'), с указанием имени пассажира и контактных данных
select b.book_ref, b.book_date, t.passenger_name, t.contact_data, tf.fare_conditions
from bookings as b join tickets as t using(book_ref) join ticket_flights as tf using(ticket_no)
where tf.fare_conditions='Business'
order by b.book_date desc
    limit 10;
--5.	Найти все рейсы, у которых нет забронированных мест в бизнес-классе (fare_conditions = 'Business')
select DISTINCT f.flight_no
from flights as f join (select * from ticket_flights where fare_conditions!='Business') as tf using(flight_id);
--6.	Получить список аэропортов (airport_name) и городов (city), в которых есть рейсы с задержкой по вылету
select DISTINCT a.airport_name, a.city
from airports_data as a join flights as f on a.airport_code=f.departure_airport
where f.status='Delayed';
--7.	Получить список аэропортов (airport_name) и количество рейсов, вылетающих из каждого аэропорта, отсортированный по убыванию количества рейсов
select a.airport_name,count(*) as flights_count
from airports_data as a join flights as f on a.airport_code=f.departure_airport
where f.status in('Delayed','Scheduled','On Time')
group by a.airport_name
order by flights_count desc;
--8.	Найти все рейсы, у которых запланированное время прибытия (scheduled_arrival) было изменено и новое время прибытия (actual_arrival) не совпадает с запланированным
select flight_no, scheduled_arrival, actual_arrival
from flights
where scheduled_arrival!=actual_arrival;
--9.	Вывести код, модель самолета и места не эконом класса для самолета "Аэробус A321-200" с сортировкой по местам
select ad.aircraft_code, ad.model, s.seat_no, s.fare_conditions
from aircrafts_data as ad join seats as s using(aircraft_code)
where ad.model->>'ru' like '%Аэробус A321-200%' and fare_conditions!='Economy'
order by s.seat_no;
--10.	Вывести города, в которых больше 1 аэропорта (код аэропорта, аэропорт, город)
select ad.airport_code, ad.airport_name, ad.city
from airports_data as ad join (select city, count(airport_name)
                               from airports_data
                               group by city
                               having count(airport_name)>1) as selected_aiports
                              using(city);
--11.	Найти пассажиров, у которых суммарная стоимость бронирований превышает среднюю сумму всех бронирований
select t.passenger_id, t.passenger_name, b.total_amount
from bookings as b join tickets as t using(book_ref)
where b.total_amount>(select avg(total_amount) as avg_book from bookings);
--12.	Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация
select f.flight_no, ad.city as from, ad2.city as to, f.scheduled_departure
from flights as f join airports_data as ad on (ad.city->>'ru'='Екатеринбург' and f.departure_airport=ad.airport_code)
    join airports_data as ad2 on (ad2.city->>'ru'='Москва' and f.arrival_airport=ad2.airport_code)
where f.status in('Scheduled', 'On Time', 'Delayed')
order by f.scheduled_departure
    limit 1;
--13.	Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)
select tf.amount as min_and_max_ticket_cost, string_agg(tf.ticket_no,', ') as ticket_numbers
from ticket_flights as tf join (select max(amount) as max_ticket_cost, min(amount) as min_ticket_cost
                                from ticket_flights) as val
                               on val.min_ticket_cost=tf.amount or val.max_ticket_cost=tf.amount
group by tf.amount;
--14.	Написать DDL таблицы Customers, должны быть поля id, firstName, LastName, email, phone. Добавить ограничения на поля (constraints)
CREATE TABLE IF NOT EXISTS bookings.customers (
                                                  id integer UNIQUE NOT NULL,
                                                  first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    email character varying(100),
    phone character varying(13),
    CONSTRAINT customers_pkey PRIMARY KEY (id),
    CONSTRAINT customers_phone_check CHECK(phone LIKE '+___________')
    );
--15.	Написать DDL таблицы Orders, должен быть id, customerId, quantity. Должен быть внешний ключ на таблицу customers + constraints
CREATE TABLE IF NOT EXISTS bookings.orders (
                                               id integer UNIQUE NOT NULL,
                                               customer_id integer NOT NULL,
                                               quantity integer NOT NULL,
                                               CONSTRAINT orders_pkey PRIMARY KEY (id),
    CONSTRAINT orders_fkey FOREIGN KEY (customer_id)
    REFERENCES bookings.customers (id)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION,
    CONSTRAINT orders_quantity_check CHECK(quantity>=0)
    );
--16.	Написать 5 insert в эти таблицы
INSERT INTO customers VALUES (1, 'Andrei', 'Andreev', 'andrei@mail.ru','+375000000000'),
                             (2, 'Ivan', 'Ivanov', 'ivan@mail.ru','+375111111111'),
                             (3, 'Petya', 'Petrov', 'petya@mail.ru','+375222222222'),
                             (4, 'Semen', 'Semenov', 'semen@mail.ru','+375333333333'),
                             (5, 'Vasya', 'Vasilyev', 'vasya@mail.ru','+375444444444');
INSERT INTO orders VALUES (1, 1, 10),
                          (2, 1, 5),
                          (3, 4, 7),
                          (4, 2, 8),
                          (5, 3, 1);
--17.	Удалить таблицы
DROP TABLE orders;
DROP TABLE customers;
