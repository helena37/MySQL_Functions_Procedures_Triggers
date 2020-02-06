USE soft_uni;
#Exercise 1 - Employees with Salary Above 35000
CREATE PROCEDURE usp_get_employees_salary_above_35000()
BEGIN
    SELECT first_name,
           last_name
    FROM employees
    WHERE salary > 35000
    ORDER BY first_name,
             last_name,
             employee_id;
end;

CALL usp_get_employees_salary_above_35000();

#Exercise 2 - Employees with Salary Above Number
CREATE PROCEDURE usp_get_employees_salary_above(input_salary DECIMAL(19, 4))
BEGIN
    SELECT first_name,
           last_name
    FROM employees
    WHERE salary >= input_salary
    ORDER BY first_name,
             last_name,
             employee_id;
end;

CALL usp_get_employees_salary_above(48100);

#Exercise 3 - Town Names Starting With
CREATE PROCEDURE usp_get_towns_starting_with(town_name TEXT)
BEGIN
    SELECT name AS town_name
    FROM towns
    WHERE name LIKE CONCAT(town_name, '%')
    ORDER BY name;

end;

CALL usp_get_towns_starting_with('b');

#Exercise 4 - Employees from Town
CREATE PROCEDURE usp_get_employees_from_town(town_name VARCHAR(50))
begin
    SELECT e.first_name,
           e.last_name
    FROM employees e
             JOIN addresses a ON e.address_id = a.address_id
             JOIN towns t ON a.town_id = t.town_id
    WHERE t.name = town_name
    ORDER BY e.first_name,
             e.last_name,
             e.employee_id;
end;

CALL usp_get_employees_from_town('Sofia');

#Exercise 5 - Salary Level Function
CREATE FUNCTION ufn_get_salary_level(e_salary DECIMAL(19, 4))
    RETURNS VARCHAR(20)
    DETERMINISTIC
BEGIN
    DECLARE salary_level VARCHAR(20);
    IF e_salary < 30000 THEN
        SET salary_level = 'Low';
    ELSEIF e_salary BETWEEN 30000 AND 50000 THEN
        SET salary_level = 'Average';
    ElSEIF e_salary > 50000 THEN
        SET salary_level = 'High';
    END IF;
    RETURN salary_level;
end;

SELECT e.salary,
       ufn_get_salary_level(e.salary)
FROM employees e;

#Exercise 6 - Employees by Salary Level
CREATE PROCEDURE usp_get_employees_by_salary_level(salary_level VARCHAR(7))
BEGIN
    SELECT e.first_name,
           e.last_name
    FROM employees e
    WHERE CASE
              WHEN e.salary < 30000 THEN salary_level = 'Low'
              WHEN e.salary BETWEEN 30000 AND 50000 THEN salary_level = 'Average'
              ELSE salary_level = 'High'
              END
    ORDER BY e.first_name DESC,
             e.last_name DESC;
END;

CALL usp_get_employees_by_salary_level('High');

#Exercise 7 - Define Function
CREATE FUNCTION ufn_is_word_comprised(set_of_letters varchar(50), word varchar(50))
    RETURNS BIT
BEGIN
    DECLARE result BIT;
    DECLARE word_length INT;
    DECLARE current_index INT;

    SET result := 1;
    SET word_length := CHAR_LENGTH(word);
    SET current_index := 1;

    WHILE (current_index <= word_length)
        DO
            IF (set_of_letters NOT LIKE CONCAT('%', SUBSTRING(word, current_index, 1), '%'))
            THEN
                SET result := 0;
            END IF;
            SET current_index := current_index + 1;
        end while;
    RETURN result;
END;

SELECT ufn_is_word_comprised('oistmiahf', 'Sofia'),
       ufn_is_word_comprised('oistmiahf', 'halves'),
       ufn_is_word_comprised('bobr', 'Rob');


USE bank_accounts;
#Exercise 8 - Find Full Name
CREATE PROCEDURE usp_get_holders_full_name()
BEGIN
    SELECT CONCAT(first_name, ' ', last_name) AS full_name
    FROM account_holders
    ORDER BY full_name,
             id;
end;

CALL usp_get_holders_full_name();

#Exercise 9 - People with Balance Higher Than
CREATE PROCEDURE usp_get_holders_with_balance_higher_than(input_number DECIMAL(19, 4))
BEGIN
    SELECT ah.first_name,
           ah.last_name
    FROM account_holders ah
             JOIN accounts a ON ah.id = a.account_holder_id
    GROUP BY ah.id
    HAVING SUM(a.balance) > input_number
    ORDER BY ah.id;
end;

CALL usp_get_holders_with_balance_higher_than(7000);


#Exercise 10 - Future Value Function
CREATE FUNCTION ufn_calculate_future_value(sum DOUBLE, yearly_interest_rate DOUBLE, number_of_years INT)
    RETURNS DECIMAL(19, 4)
BEGIN
    DECLARE future_value DOUBLE;
    SET future_value := sum * POW((1 + yearly_interest_rate), number_of_years);
    RETURN future_value;
end;

SELECT ufn_calculate_future_value(1000, 0.1, 5);

#Exercise 11 - Calculating Interest
CREATE PROCEDURE usp_calculate_future_value_for_account(id_account INT, interest_rate DECIMAL(19, 4))
BEGIN
    SELECT a.id,
           ah.first_name,
           ah.last_name,
           a.balance,
           ufn_calculate_future_value(a.balance, interest_rate, 5)
    FROM accounts a
             JOIN account_holders ah ON a.account_holder_id = ah.id
    WHERE a.id = id_account;
end;

CALL usp_calculate_future_value_for_account(1, 0.1);

#Exercise 12 - Deposit Money
CREATE PROCEDURE usp_deposit_money(account_id INT, money_amount DECIMAL(19, 4))
BEGIN
    IF money_amount > 0 THEN
        START TRANSACTION;
        UPDATE `accounts` AS a
        SET a.balance = a.balance + money_amount
        WHERE a.id = account_id;
        IF (SELECT a.balance
            FROM `accounts` AS a
            WHERE a.id = account_id) < 0
        THEN
            ROLLBACK;
        ELSE
            COMMIT;
        END IF;
    END IF;
END;

#Exercise 13 - Withdraw Money
CREATE PROCEDURE usp_withdraw_money(
    account_id INT, money_amount DECIMAL(19, 4))
BEGIN
    IF money_amount > 0 THEN
START TRANSACTION;
UPDATE `accounts` AS a
SET
a.balance = a.balance - money_amount
WHERE
a.id = account_id;
        IF (SELECT a.balance
FROM `accounts` AS a
WHERE a.id = account_id) < 0
            THEN ROLLBACK;
        ELSE
            COMMIT;
        END IF;
    END IF;
END;


#Exercise 14 - 14.	Money Transfer
CREATE PROCEDURE usp_transfer_money(
    from_account_id INT, to_account_id INT, money_amount DECIMAL(19, 4))
BEGIN
    IF money_amount > 0
        AND from_account_id <> to_account_id
        AND (SELECT a.id
            FROM `accounts` AS a
            WHERE a.id = to_account_id) IS NOT NULL
        AND (SELECT a.id
            FROM `accounts` AS a
            WHERE a.id = from_account_id) IS NOT NULL
        AND (SELECT a.balance
            FROM `accounts` AS a
            WHERE a.id = from_account_id) >= money_amount
    THEN
        START TRANSACTION;

        UPDATE `accounts` AS a
        SET
            a.balance = a.balance + money_amount
        WHERE
            a.id = to_account_id;

        UPDATE `accounts` AS a
        SET
            a.balance = a.balance - money_amount
        WHERE
            a.id = from_account_id;

        IF (SELECT a.balance
            FROM `accounts` AS a
            WHERE a.id = from_account_id) < 0
            THEN ROLLBACK;
        ELSE
            COMMIT;
        END IF;
    END IF;
END;


#Exercise 15 - Log Accounts Trigger
CREATE TABLE `logs` (
    log_id INT NOT NULL AUTO_INCREMENT,
    account_id INT(11),
    old_sum DECIMAL(19, 4),
    new_sum DECIMAL(19, 4),
    CONSTRAINT PRIMARY KEY pk_logs
                    (log_id)
);

CREATE TRIGGER tr_logs
AFTER UPDATE ON `accounts`
FOR EACH ROW
BEGIN
        INSERT INTO `logs`
            (`account_id`, `old_sum`, `new_sum`)
        VALUES (OLD.id, OLD.balance, NEW.balance);
END;

#Exercise 16 - Emails Trigger
CREATE TABLE `notification_emails` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `recipient` INT(11) NOT NULL,
    `subject` VARCHAR(50) NOT NULL,
    `body` VARCHAR(255) NOT NULL,
    CONSTRAINT PRIMARY KEY pk_notification_emails
                                   (id)
);

CREATE TRIGGER `tr_notification_emails`
AFTER INSERT ON `logs`
FOR EACH ROW
BEGIN
    INSERT INTO `notification_emails`
        (`recipient`, `subject`, `body`)
    VALUES (
        NEW.account_id,
        CONCAT('Balance change for account: ', NEW.account_id),
        CONCAT('On ', DATE_FORMAT(NOW(), '%b %d %Y at %r'), ' your balance was changed from ', ROUND(NEW.old_sum, 2), ' to ', ROUND(NEW.new_sum, 2), '.'));
END;
