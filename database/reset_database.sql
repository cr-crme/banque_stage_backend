/* Use the database (create if not exist) */
USE dev_db;

/* Clear the database */
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS entities;
DROP TABLE IF EXISTS phone_numbers;
DROP TABLE IF EXISTS addresses;

DROP TABLE IF EXISTS persons;

DROP TABLE IF EXISTS teaching_groups;
DROP TABLE IF EXISTS teachers;

DROP TABLE IF EXISTS enterprise_addresses;
DROP TABLE IF EXISTS enterprise_headquarter_addresses;
DROP TABLE IF EXISTS enterprise_phone_numbers;
DROP TABLE IF EXISTS enterprise_fax_numbers;
DROP TABLE IF EXISTS enterprise_activity_types;
DROP TABLE IF EXISTS enterprise_contacts;
DROP TABLE IF EXISTS enterprise_jobs;
DROP TABLE IF EXISTS enterprise_job_photo_urls;
DROP TABLE IF EXISTS enterprise_job_comments;
DROP TABLE IF EXISTS enterprise_job_pre_internship_requests;
DROP TABLE IF EXISTS enterprises;

SET FOREIGN_KEY_CHECKS = 1;


/***********/
/* GENERIC */
/***********/

CREATE TABLE entities (
    shared_id VARCHAR(36) NOT NULL PRIMARY KEY
);


CREATE TABLE addresses (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    entity_id VARCHAR(36) NOT NULL,
    civic INT,
    street VARCHAR(100),
    apartment VARCHAR(20),
    city VARCHAR(50),
    postal_code VARCHAR(10),
    FOREIGN KEY (entity_id) REFERENCES entities(shared_id) ON DELETE CASCADE
);

CREATE TABLE phone_numbers (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    entity_id VARCHAR(36) NOT NULL,
    phone_number VARCHAR(20) NOT NULL, 
    FOREIGN KEY (entity_id) REFERENCES entities(shared_id) ON DELETE CASCADE
);


/*************************/
/* People related tables */
/*************************/

/**** Generic persons ****/

CREATE TABLE persons (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    last_name VARCHAR(50) NOT NULL,
    date_birthday DATE,
    email VARCHAR(100),
    FOREIGN KEY (id) REFERENCES entities(shared_id) ON DELETE CASCADE
);


/**** Teachers ****/

CREATE TABLE teachers (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    school_id VARCHAR(50) NOT NULL, 
    FOREIGN KEY (id) REFERENCES persons(id) ON DELETE CASCADE
);

CREATE TABLE teaching_groups (
    teacher_id VARCHAR(36) NOT NULL,
    group_name VARCHAR(20) NOT NULL, 
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);


/**** Students ****/
/* TODO */





/*************************/
/* People related tables */
/*************************/

CREATE TABLE enterprises (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    recruiter_id VARCHAR(36) NOT NULL, 
    contact_function VARCHAR(255) NOT NULL,
    website VARCHAR(255) NOT NULL,
    neq VARCHAR(50) NOT NULL,
    FOREIGN KEY (id) REFERENCES entities(shared_id) ON DELETE CASCADE
);

CREATE TABLE enterprise_contacts(
    enterprise_id VARCHAR(36) NOT NULL,
    contact_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (contact_id) REFERENCES persons(id),
    FOREIGN KEY (enterprise_id) REFERENCES enterprises(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_addresses(
    enterprise_id VARCHAR(36) NOT NULL,
    address_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (address_id) REFERENCES addresses(id),
    FOREIGN KEY (enterprise_id) REFERENCES enterprises(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_headquarter_addresses(
    enterprise_id VARCHAR(36) NOT NULL,
    address_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (address_id) REFERENCES addresses(id),
    FOREIGN KEY (enterprise_id) REFERENCES enterprises(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_phone_numbers(
    enterprise_id VARCHAR(36) NOT NULL,
    phone_number_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (phone_number_id) REFERENCES phone_numbers(id),
    FOREIGN KEY (enterprise_id) REFERENCES enterprises(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_fax_numbers(
    enterprise_id VARCHAR(36) NOT NULL,
    fax_number_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (fax_number_id) REFERENCES phone_numbers(id),
    FOREIGN KEY (enterprise_id) REFERENCES enterprises(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_activity_types(
    enterprise_id VARCHAR(36) NOT NULL,
    activity_type VARCHAR(50) NOT NULL,
    FOREIGN KEY (enterprise_id) REFERENCES enterprises(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_jobs(
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    enterprise_id VARCHAR(36) NOT NULL,
    positions_offered INT NOT NULL,
    minimum_age INT NOT NULL,
    FOREIGN KEY (enterprise_id) REFERENCES enterprises(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_job_photo_urls(
    job_id VARCHAR(36) NOT NULL,
    photo_url VARCHAR(255) NOT NULL,
    FOREIGN KEY (job_id) REFERENCES enterprise_jobs(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_job_comments(
    job_id VARCHAR(36) NOT NULL,
    comment VARCHAR(255) NOT NULL,
    FOREIGN KEY (job_id) REFERENCES enterprise_jobs(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_job_pre_internship_requests(
    job_id VARCHAR(36) NOT NULL,
    request VARCHAR(50) NOT NULL,
    FOREIGN KEY (job_id) REFERENCES enterprise_jobs(id) ON DELETE CASCADE
);
