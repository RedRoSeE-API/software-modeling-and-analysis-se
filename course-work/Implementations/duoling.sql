DROP TABLE IF EXISTS User_Progress CASCADE;
DROP TABLE IF EXISTS Exercise CASCADE;
DROP TABLE IF EXISTS Lesson CASCADE;
DROP TABLE IF EXISTS Course CASCADE;
DROP TABLE IF EXISTS Language CASCADE;
DROP TABLE IF EXISTS "user" CASCADE;

CREATE TABLE "user" (
    user_id SERIAL PRIMARY KEY,s
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Language (
    language_id SERIAL PRIMARY KEY,
    language_name VARCHAR(50) NOT NULL,
    language_code VARCHAR(5) NOT NULL UNIQUE
);

CREATE TABLE Course (
    course_id SERIAL PRIMARY KEY,
    from_language_id INTEGER NOT NULL,
    to_language_id INTEGER NOT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    FOREIGN KEY (from_language_id) REFERENCES Language(language_id),
    FOREIGN KEY (to_language_id) REFERENCES Language(language_id)
);

CREATE TABLE Lesson (
    lesson_id SERIAL PRIMARY KEY,
    course_id INTEGER NOT NULL,
    title VARCHAR(100) NOT NULL,
    order_number INTEGER NOT NULL,
    difficulty_level VARCHAR(20),
    FOREIGN KEY (course_id) REFERENCES Course(course_id) ON DELETE CASCADE
);

CREATE TABLE Exercise (
    exercise_id SERIAL PRIMARY KEY,
    lesson_id INTEGER NOT NULL,
    question_text TEXT NOT NULL,
    correct_answer VARCHAR(255) NOT NULL,
    FOREIGN KEY (lesson_id) REFERENCES Lesson(lesson_id) ON DELETE CASCADE
);

CREATE TABLE User_Progress (
    user_id INTEGER NOT NULL,
    lesson_id INTEGER NOT NULL,
    completed_date TIMESTAMP,
    score INTEGER,
    attempts_count INTEGER DEFAULT 1,
    is_completed BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (user_id, lesson_id),
    FOREIGN KEY (user_id) REFERENCES "user"(user_id) ON DELETE CASCADE,
    FOREIGN KEY (lesson_id) REFERENCES Lesson(lesson_id) ON DELETE CASCADE
);

-- Procedure
CREATE OR REPLACE PROCEDURE add_progress(
    p_user_id INTEGER,
    p_lesson_id INTEGER,
    p_score INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO User_Progress (user_id, lesson_id, score, is_completed)
    VALUES (p_user_id, p_lesson_id, p_score, (p_score >= 80))
    ON CONFLICT (user_id, lesson_id) 
    DO UPDATE SET 
        score = p_score,
        is_completed = (p_score >= 80);
END;
$$;

CALL add_progress(3, 3, 90);

-- Simple function
CREATE OR REPLACE FUNCTION count_completed_lessons(p_user_id INTEGER)
RETURNS INTEGER
LANGUAGE sql
AS $$
    SELECT COUNT(*)::INTEGER
    FROM User_Progress
    WHERE user_id = p_user_id 
      AND is_completed = TRUE;
$$;

SELECT username, count_completed_lessons(user_id) AS completed
FROM "user";


-- trigger + trigger function
CREATE OR REPLACE FUNCTION trg_update_completion_date()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_completed = TRUE THEN
        NEW.completed_date := NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_complete_timestamp
    BEFORE INSERT OR UPDATE ON User_Progress
    FOR EACH ROW
    WHEN (NEW.is_completed = TRUE)
    EXECUTE FUNCTION trg_update_completion_date();





-- trunkate all tables
TRUNCATE TABLE "user" CASCADE;
TRUNCATE TABLE Language CASCADE;

ALTER SEQUENCE user_user_id_seq RESTART WITH 1;
ALTER SEQUENCE language_language_id_seq RESTART WITH 1;
ALTER SEQUENCE course_course_id_seq RESTART WITH 1;
ALTER SEQUENCE lesson_lesson_id_seq RESTART WITH 1;
ALTER SEQUENCE exercise_exercise_id_seq RESTART WITH 1;