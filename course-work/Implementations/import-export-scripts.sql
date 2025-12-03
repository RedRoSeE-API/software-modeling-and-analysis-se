-- 1. Languages (10 real languages)
INSERT INTO Language (language_name, language_code) VALUES
('English', 'en'),
('Spanish', 'es'),
('French', 'fr'),
('German', 'de'),
('Italian', 'it'),
('Portuguese', 'pt'),
('Russian', 'ru'),
('Japanese', 'ja'),
('Korean', 'ko'),
('Chinese (Simplified)', 'zh');

-- 2. Users (500 fake users)
INSERT INTO "user" (username, email, password, created_at)
SELECT 
    'user' || n,
    'user' || n || '@example.com',
    '$2y$10$whjM3vH9l5z7k examplehashedpassword',  -- same dummy hash for all
    TIMESTAMP '2024-01-01' + RANDOM() * INTERVAL '700 days'
FROM GENERATE_SERIES(1,500) AS n;

-- 3. Courses (24 popular language pairs)
INSERT INTO Course (from_language_id, to_language_id, title, description) VALUES
(1,2,'English → Spanish Beginner','Complete beginner course'),
(1,2,'English → Spanish Intermediate','Build fluency'),
(1,3,'English → French A1-A2','From zero to hero'),
(1,3,'English → French B1-B2','Intermediate French'),
(1,4,'English → German Complete','A1 to B2 in one course'),
(2,1,'Spanish → English for Native Speakers','Perfect for Spanish speakers'),
(3,1,'French → English Advanced','C1-C2 level'),
(1,8,'English → Japanese for Beginners','Hiragana, Katakana & basic grammar'),
(1,9,'English → Korean Beginner','Hangul + Top 500 words'),
(1,10,'English → Chinese (Mandarin)','HSK 1-3 level content'),
(2,3,'Spanish → French','For Spanish speakers learning French'),
(4,1,'German → English Business','Business German to English'),
(1,5,'English → Italian Beginner','Ciao! Start speaking today'),
(5,1,'Italian → English Intermediate','Improve your English from Italian');

-- Add a few more to reach ~24 courses if you want
INSERT INTO Course (from_language_id, to_language_id, title, description) VALUES
(1,6,'English → Portuguese (Brazil)','European + Brazilian variants'),
(6,1,'Portuguese → English','For Brazilian and European speakers'),
(1,7,'English → Russian A1-A2','Cyrillic + basic phrases'),
(8,1,'Japanese → English','For Japanese natives'),
(3,2,'French → Spanish','Perfect bridge course');

-- 4. Lessons (≈ 15-30 lessons per course → ~400 lessons total)
INSERT INTO Lesson (course_id, title, order_number, difficulty_level)
SELECT 
    c.course_id,
    'Lesson ' || n || ': ' || 
    CASE 
        WHEN n <= 5 THEN 'Basics & Greetings'
        WHEN n <= 10 THEN 'Vocabulary & Grammar'
        WHEN n <= 15 THEN 'Daily Conversations'
        WHEN n <= 20 THEN 'Reading & Writing'
        ELSE 'Culture & Advanced Topics'
    END,
    n,
    CASE 
        WHEN n <= 8 THEN 'Beginner'
        WHEN n <= 16 THEN 'Elementary'
        WHEN n <= 24 THEN 'Intermediate'
        ELSE 'Advanced'
    END
FROM Course c
CROSS JOIN GENERATE_SERIES(1,28) AS n;

-- 5. Exercises (5 exercises per lesson → ~2000 exercises)
INSERT INTO Exercise (lesson_id, question_text, correct_answer)
SELECT 
    l.lesson_id,
    'Translate: ' || 
    CASE (RANDOM()*10)::INT
        WHEN 0 THEN 'Hello' WHEN 1 THEN 'Thank you' WHEN 2 THEN 'Good morning'
        WHEN 3 THEN 'How are you?' WHEN 4 THEN 'Yes' WHEN 5 THEN 'No'
        WHEN 6 THEN 'Please' WHEN 7 THEN 'Goodbye' WHEN 8 THEN 'Water'
        ELSE 'I love learning languages'
    END,
    CASE (RANDOM()*10)::INT
        WHEN 0 THEN 'Hola' WHEN 1 THEN 'Gracias' WHEN 2 THEN 'Buenos días'
        WHEN 3 THEN '¿Cómo estás?' WHEN 4 THEN 'Sí' WHEN 5 THEN 'No'
        WHEN 6 THEN 'Por favor' WHEN 7 THEN 'Adiós' WHEN 8 THEN 'Agua'
        ELSE 'Me encanta aprender idiomas'
    END
FROM Lesson l
CROSS JOIN GENERATE_SERIES(1,5);

-- 6. User_Progress (realistic completion data for all 500 users)
-- Some users are very active, some barely started, some in the middle
INSERT INTO User_Progress (user_id, lesson_id, completed_date, score, attempts_count, is_completed)
SELECT 
    u.user_id,
    l.lesson_id,
    -- Random completion date within the last 2 years
    CASE 
        WHEN RANDOM() < 0.7 THEN  -- 70% of possible progress is actually completed
            TIMESTAMP '2024-01-01' + RANDOM() * INTERVAL '700 days'
        ELSE NULL
    END,
    CASE WHEN RANDOM() < 0.7 THEN NULL ELSE FLOOR(RANDOM()*41 + 60)::INT END, -- score 60-100
    CASE WHEN RANDOM() < 0.7 THEN NULL ELSE (RANDOM()*4 + 1)::INT END,      -- attempts 1-5
    CASE WHEN RANDOM() < 0.7 THEN TRUE ELSE FALSE END
FROM "user" u
CROSS JOIN Lesson l
WHERE 
    -- Simulate realistic drop-off: users rarely finish everything
    RANDOM() < 
    CASE 
        WHEN u.user_id <= 50 THEN 0.95    -- top 50 users are power users
        WHEN u.user_id <= 200 THEN 0.50   -- medium activity
        ELSE 0.15                         -- low activity / new users
    END;

-- psql command to export data to csv files
PGPASSWORD='your_password' psql -h localhost -p 8000 -U postgres -d duolingo -c "\COPY \"user\" TO '$(pwd)/user.csv' WITH CSV HEADER"
PGPASSWORD='your_password' psql -h localhost -p 8000 -U postgres -d duolingo -c "\COPY Language TO '$(pwd)/language.csv' WITH CSV HEADER"
PGPASSWORD='your_password' psql -h localhost -p 8000 -U postgres -d duolingo -c "\COPY Course TO '$(pwd)/course.csv' WITH CSV HEADER"
PGPASSWORD='your_password' psql -h localhost -p 8000 -U postgres -d duolingo -c "\COPY Lesson TO '$(pwd)/lesson.csv' WITH CSV HEADER"
PGPASSWORD='your_password' psql -h localhost -p 8000 -U postgres -d duolingo -c "\COPY Exercise TO '$(pwd)/exercise.csv' WITH CSV HEADER"
PGPASSWORD='your_password' psql -h localhost -p 8000 -U postgres -d duolingo -c "\COPY User_Progress TO '$(pwd)/user_progress.csv' WITH CSV HEADER"
