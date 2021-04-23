--1
SELECT s.name, s.surnmane, h.name
FROM hobby_student sh
INNER JOIN hobby h
ON h.id = sh.hobby_id
INNER JOIN student s
ON s.id = sh.id
WHERE sh.date_finish IS NULL

--2
SELECT s.name, s.surnmane, h.name
FROM hobby_student sh
INNER JOIN hobby h
ON h.id = sh.hobby_id
INNER JOIN student s
ON s.id = sh.id
WHERE sh.date_finish IS NULL
AND sh.date_start = (SELECT MIN(sh.date_start)
FROM hobby_student sh WHERE sh.date_finish IS NULL)

--3
SELECT s.name, s.surnmane, s.id, s.date_birth
FROM hobby_student sh
INNER JOIN hobby h
ON h.id = sh.hobby_id
INNER JOIN student s
ON s.id = sh.id


--4
SELECT s.name, s.surnmane, s.id, s.date_birth, extract(month from age(date_finish, date_start))
FROM hobby_student sh
INNER JOIN hobby h
ON h.id = sh.hobby_id
INNER JOIN student s
ON s.id = sh.id
WHERE sh.date_finish IS NOT NULL

--5   	---
SELECT s.name, s.surnmane, s.id, s.date_birth
FROM hobby_student sh
INNER JOIN hobby h
ON h.id = sh.hobby_id
INNER JOIN student s
ON s.id = sh.id
WHERE 0 = extract(year from age(date_finish, date_start))


--6
SELECT round(avg(s.score),2), s.n_group
FROM hobby_student sh 
INNER JOIN hobby h
ON h.id = sh.hobby_id 
INNER JOIN student s
ON s.id = sh.id 
WHERE sh.date_finish IS NULL
GROUP BY s.n_group


--7
SELECT h.name, h.risk, 
EXTRACT(year from age(sh.date_start)) * 12
+ EXTRACT(month from age(NOW(),sh.date_start)) as months
FROM hobby h,hobby_student sh
WHERE sh.hobby_id = h.id AND
sh.date_start =
(SELECT MIN(date_start)
FROM hobby_student
WHERE date_finish IS NULL)


--8 Найти все хобби, которыми увлекаются студенты, имеющие максимальный балл.

SELECT h.name
	FROM hobby h, hobby_student sh, student s
	WHERE sh.hobby_id = h.id AND 
	s.id = sh.id AND
	s.score = (SELECT MAX(s_.score)
			  FROM student s_)
GROUP BY h.name


--9 Найти все действующие хобби, которыми увлекаются троечники 2-го курса.

SELECT h.name --, s.score
	FROM hobby h, hobby_student sh, student s
		WHERE sh.hobby_id = h.id AND 
			s.id = sh.id AND
			s.score BETWEEN 3 and 4 AND
			s.n_group::VARCHAR LIKE '2%'
GROUP BY h.name



--10 Найти номера курсов, на которых более 50% с
--   студентов имеют более одного действующего хобби.

SELECT DISTINCT chr(ascii(s.n_group::varchar)) AS course --,t.count_h, tmpt.count_all
FROM student s
INNER JOIN (SELECT tmpt.count as count_h, chr(ascii(n_group::varchar)) AS course_tmp, s.id
			FROM student s,
				(SELECT COUNT(id), id
				FROM hobby_student sh
				WHERE date_finish IS NULL
				GROUP BY id
			)tmpt
			WHERE s.id = tmpt.id
)t
ON s.id = t.id
LEFT JOIN (SELECT COUNT(tmp.course_tmp) as count_all, tmp.course_tmp
		   FROM(SELECT chr(ascii(n_group::varchar)) AS course_tmp
		   		FROM student
		   )tmp
		  GROUP BY tmp.course_tmp
)tmpt
ON tmpt.course_tmp = t.course_tmp
WHERE t.count_h < 0.5 * tmpt.count_all
GROUP BY course


--11 Вывести номера групп, в которых не менее 60% студентов имеют балл не ниже 4.

SELECT st.n_group
FROM student st
INNER JOIN (
	SELECT COUNT(s.score) as cnt, s.n_group
	FROM student s
	WHERE s.score >= 4
	GROUP BY s.n_group
)tmp
ON st.n_group = tmp.n_group
INNER JOIN (
	SELECT COUNT(s_.score), s_.n_group
		FROM student s_
		GROUP BY s_.n_group
)tmp_
ON tmp.n_group = tmp_.n_group
WHERE cnt >= 0.6*count
GROUP BY st.n_group
 

--12 Для каждого курса подсчитать количество различных действующих хобби на курсе.

SELECT DISTINCT chr(ascii(s.n_group::varchar)) AS course, COUNT(DISTINCT(h.name))
	FROM hobby_student sh, student s, hobby h
		WHERE sh.id = s.id AND h.id = sh.hobby_id AND
		sh.date_finish IS NULL
GROUP BY course



--13 Вывести номер зачётки, фамилию и имя, дату рождения и номер курса 
--   для всех отличников, не имеющих хобби. Отсортировать данные по возрастанию 
--   в пределах курса по убыванию даты рождения.

SELECT chr(ascii(s.n_group::varchar)) AS course, s.id, s.name, s.surnmane, s.date_birth
	FROM student s
		WHERE s.score > 4.75
GROUP BY 
	s.id, s.name, s.surnmane, course, s.date_birth
ORDER BY
	s.date_birth DESC

--14 Создать представление, в котором отображается вся информация о студентах, 
--   которые продолжают заниматься хобби в данный момент и занимаются им как минимум 5 лет.

CREATE OR REPLACE VIEW new_view14 AS
SELECT s.*
FROM student s
INNER JOIN
(
	SELECT DISTINCT sh.id 
	FROM hobby_student sh
	WHERE sh.date_finish IS NULL AND 
	EXTRACT(year FROM (justify_days(now() - sh.date_start))) >= 5
)t
ON s.id = t.id;

SELECT *
FROM new_view14



--15 Для каждого хобби вывести количество людей, которые им занимаются.

CREATE OR REPLACE VIEW new_view15 AS
SELECT COUNT(s.id), h.name
FROM hobby_student sh, student s, hobby h
WHERE sh.id = s.id AND h.id = sh.hobby_id 
AND sh.date_finish is NULL
GROUP BY h.name



--16 Вывести ИД самого популярного хобби.

CREATE OR REPLACE VIEW new_view15 AS
	SELECT COUNT(s.id), h.name
		FROM hobby_student sh, student s, hobby h
		WHERE sh.id = s.id AND h.id = sh.hobby_id 
		AND sh.date_finish is NULL
	GROUP BY h.name;
CREATE OR REPLACE VIEW new_view16 AS
	SELECT COUNT(s.id) as cn, h.name, h.id
		FROM hobby_student sh, student s, hobby h
		WHERE sh.id = s.id AND h.id = sh.hobby_id 
		AND sh.date_finish is NULL 
	GROUP BY h.name,h.id;
SELECT nww.id
		FROM new_view15 nw, new_view16 nww
		WHERE nw.count = (SELECT MAX(count) FROM new_view15) AND
		nw.name = nww.name


--17 Вывести всю информацию о студентах, занимающихся самым популярным хобби.

SELECT *
		FROM hobby_student sh, student s
		WHERE sh.id = s.id AND sh.hobby_id = (
			SELECT nww.id
				FROM new_view15 nw, new_view16 nww
				WHERE nw.count = (SELECT MAX(count) FROM new_view15) AND
				nw.name = nww.name)


	
--18 Вывести ИД 3х хобби с максимальным риском.

SELECT h.id
	FROM hobby h
	ORDER BY h.risk DESC
LIMIT 3



--19 Вывести 10 студентов, которые занимаются одним (или несколькими) хобби самое продолжительно время.

SELECT DISTINCT s.name, s.surnmane,  sh.date_start
	FROM hobby h, hobby_student sh, student s
		WHERE sh.hobby_id = h.id AND s.id = sh.id AND sh.date_finish is NULL
		ORDER BY sh.date_start 
LIMIT 10





--20 Вывести номера групп (без повторений), в которых учатся студенты из предыдущего запроса.

CREATE OR REPLACE VIEW new_view20_ AS
	SELECT DISTINCT n_group, s.name, s.surnmane, sh.date_start
		FROM hobby h, hobby_student sh, student s
			WHERE sh.hobby_id = h.id AND s.id = sh.id AND sh.date_finish is NULL
	ORDER BY sh.date_start 
LIMIT 10;

SELECT nw.n_group
FROM new_view20_ nw
GROUP BY 
	nw.n_group



--21 Создать представление, которое выводит номер зачетки, имя и фамилию студентов, 
--   отсортированных по убыванию среднего балла.

CREATE OR REPLACE VIEW new_view21 AS
SELECT s.id, s.name, s.surnmane
FROM student s
ORDER BY s.score DESC

--22 Представление: найти каждое популярное хобби на каждом курсе.

CREATE OR REPLACE VIEW tmp_view1 AS
SELECT COUNT(tmp.s_id), tmp.h_id, tmp.course::integer
FROM
(
	SELECT hobby_id as h_id, sh.id as s_id, chr(ascii(n_group::varchar)) as course
	FROM hobby_student sh, student s
	WHERE sh.id = s.id
)tmp
GROUP BY tmp.h_id, tmp.course
ORDER BY tmp.course;
CREATE OR REPLACE VIEW tv AS
SELECT tv.course, MAX(tv.count) as maxx
FROM tmp_view1 tv, hobby h
WHERE tv.h_id = h.id
GROUP BY course;
SELECT tv.course, sss.name
FROM tv
INNER JOIN (SELECT h_.name, tv_.count as cnt
		   FROM tmp_view1 tv_, hobby h_
		   WHERE tv_.h_id = h_.id)sss
ON sss.cnt = tv.maxx
GROUP BY  tv.course, sss.name


--23 Представление: найти хобби с максимальным риском среди 
--	 самых популярных хобби на 2 курсе.

CREATE OR REPLACE VIEW tmp_view23 AS
SELECT MAX(tmp.risk), tmp.h_id, tmp.course::integer
FROM
(
	SELECT risk, hobby_id as h_id, sh.id as s_id, chr(ascii(n_group::varchar)) as course
	FROM hobby_student sh, student s, hobby h
	WHERE sh.id = s.id AND sh.hobby_id = h.id
)tmp
GROUP BY tmp.h_id, tmp.course
ORDER BY tmp.course	;

CREATE OR REPLACE VIEW tv23 AS
SELECT tv.course, MAX(tv.max) as maxx
FROM tmp_view23 tv, hobby h
WHERE tv.h_id = h.id
GROUP BY course;

SELECT tv23.course, sss.name
FROM tv23
INNER JOIN (SELECT h_.name, tv_.max as cnt
		   FROM tmp_view23 tv_, hobby h_
		   WHERE tv_.h_id = h_.id)sss
ON sss.cnt = tv23.maxx
GROUP BY  tv23.course, sss.name



--24 Представление: для каждого курса подсчитать количество 
--	 студентов на курсе и количество отличников.


CREATE OR REPLACE VIEW tmp_view24_ AS
SELECT tmp.course::integer, COUNT(tmp.id) as count_of_stud--, COUNT(tmp_ot.id) as count_of_stud_otl 
FROM
(
	SELECT s.id, chr(ascii(n_group::varchar)) as course
	FROM student s
)tmp
GROUP BY tmp.course;
CREATE OR REPLACE VIEW tmp_view24_1 AS
SELECT tmp_ot.course::integer, COUNT(tmp_ot.id) as count_of_stud_otl 
FROM
(
SELECT s.id, chr(ascii(n_group::varchar)) as course
FROM student s
WHERE s.score >=4.75
)tmp_ot
GROUP BY tmp_ot.course;

SELECT m_course, count_of_stud, count_of_stud_otl
FROM tmp_view24_1 v1
FULL JOIN (
	select count_of_stud, course as m_course FROM tmp_view24_ v2)v2
ON v1.course = v2.m_course  



--25 Представление: самое популярное хобби среди всех студентов.

SELECT r.name
	FROM new_view15 nw, new_view16 nww
	INNER JOIN ( select name, id from hobby h)r ON r.id = nww.id
	WHERE nw.count = (SELECT MAX(count) FROM new_view15) AND
	nw.name = nww.name



--26 Создать обновляемое представление
fffffffffffffffffffffff

--27 Для каждой буквы алфавита из имени найти максимальный, средний и минимальный балл. 
--   (Т.е. среди всех студентов, чьё имя начинается на А (Алексей, Алина, Артур, Анджела) 
--   найти то, что указано в задании. Вывести на экран тех, максимальный балл которых больше 3.6

SELECT chr(ascii(name::varchar)) as first_symb, MAX(score), MIN(score), ROUND(AVG(score), 2) as average
FROM student s
GROUP BY name

--28 Для каждой фамилии на курсе вывести максимальный и минимальный средний балл. 
--   и имеют средний балл 4.1, 4, 3.8 соответственно, а 4 Иванов учится на 3 курсе 
--   и имеет балл 4.5. На экране должно быть следующее: 2 Иванов 4.1 3.8 3 Иванов 4.5 4.5

SELECT course, s.surnmane, MAX(score), MIN(score), ROUND(AVG(score), 2) as average
FROM student s
INNER JOIN(
	SELECT chr(ascii(n_group::varchar)) as course, surnmane
	FROM student
)tmp
ON s.surnmane = tmp.surnmane
GROUP BY s.surnmane, course

--29 Для каждого года рождения подсчитать количество хобби, которыми занимаются или занимались студенты.

SELECT COUNT(h.name), yyer
FROM student s, hobby h, hobby_student hs
INNER JOIN(
	SELECT s_.id, extract(year from (date_birth)) as yyer
	FROM student s_, hobby h_, hobby_student hs_
	WHERE s_.id = hs_.student_id AND hs_.hobby_id = h_.id
)tmp
ON tmp.id = hs.student_id
WHERE s.id = hs.student_id AND hs.hobby_id = h.id 
GROUP BY yyer

--30 Для каждой буквы алфавита в имени найти максимальный и минимальный риск хобби.

SELECT chr(ascii(s_.name::varchar)) as first_symb, MAX(h_.risk), MIN(h_.risk)
FROM student s_, hobby h_, hobby_student hs_
	WHERE s_.id = hs_.student_id AND hs_.hobby_id = h_.id
GROUP BY s_.name

--31 Для каждого месяца из даты рождения вывести средний балл студентов,
--   которые занимаются хобби с названием «Футбол»

SELECT extract(month from (date_birth)) as month, ROUND(AVG(s.score),2)
	FROM student s, hobby h, hobby_student hs
WHERE s.id = hs.student_id AND hs.hobby_id = h.id AND hs.hobby_id = 2
GROUP BY month

--32 Вывести информацию о студентах, которые занимались или занимаются хотя бы 
--   1 хобби в следующем формате: Имя: Иван, фамилия: Иванов, группа: 1234

SELECT DISTINCT tmp.name, tmp.surnmane, tmp.n_group
FROM hobby_student sh
INNER JOIN
(
SELECT DISTINCT s.name, s.surnmane, s.n_group, s.id
FROM student s
)tmp
ON sh.id = tmp.id
Order by tmp.n_group

--33 Найдите в фамилии в каком по счёту символа встречается «ов». 
--   Если 0 (т.е. не встречается, то выведите на экран «не найдено».

SELECT surnmane,
CASE
	WHEN position('ov' in surnmane) = 0 THEN 'Не найдено'
	ELSE position('ov' in surnmane)::varchar
	END as position
FROM student

--34 Дополните фамилию справа символом # до 10 символов.

CREATE OR REPLACE VIEW surname_ AS
SELECT left(surnmane||'##########', 10) -- as surname
FROM student;
SELECT *
FROM surname_

--35 При помощи функции удалите все символы # из предыдущего запроса.

SELECT trim(both '#' from s.left)
FROM surname_ s

--36 Выведите на экран сколько дней в апреле 2018 года.

SELECT ('5-01-2018'::date -'4-01-2018'::date) as count_days_april_2018

--37 Выведите на экран какого числа будет ближайшая суббота.

fffffffffffffff

--38 Выведите на экран век, а также какая сейчас неделя года и день года.

SELECT date_trunc('century', now())::date as century, 
to_char(now(), 'WW') as week, 
to_char((now() - '01-01-2021'::date), 'DD')::integer + 1 as day

--39 Выведите всех студентов, которые занимались или занимаются хотя бы 1 хобби. 
--   Выведите на экран Имя, Фамилию, Названию хобби, а также надпись «занимается», 
--   если студент продолжает заниматься хобби в данный момент или «закончил», если уже не занимает.

SELECT s.name,
CASE WHEN date_finish IS NULL THEN 'занимается'
	  ELSE 'не занимается'
END as status
FROM student s
INNER JOIN(
	SELECT hs_.student_id, date_finish
	FROM hobby_student hs_
)tmp
ON s.id = tmp.student_id

--40 Для каждой группы вывести сколько студентов учится на 5,4,3,2. Использовать обычное 
--   математическое округление.

SELECT s.n_group, COUNT(s.id), round
FROM student s
INNER JOIN(
	SELECT s_.id, ROUND(score,0)
	FROM student s_
)tmp
ON s.id = tmp.id
GROUP BY s.n_group, round
ORDER BY s.n_group 
