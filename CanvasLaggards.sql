/**************************/
/**** CANVAS LAGGARDS  ****/
/****    SAM TIMME     ****/
/**** EMORY UNIVERSITY ****/
/**** INSTRUCTURECON17 ****/
/**************************/

SELECT p.integration_id as publicPersonID, /* sis_user_id or unique_name (which is login ID) may be more useful for you */
p.last_request_at
FROM canvas_data.pseudonym_dim p
JOIN canvas_data.enrollment_dim ed ON ed.user_id = p.user_id
JOIN (
	SELECT DISTINCT id
	FROM canvas_data.course_dim
	WHERE workflow_state != 'deleted'
	AND enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id IN ('FA16','SP17','FA17')) /* Selecting courses from semesters in the left join counts */
	AND name NOT LIKE '%Dissertation%' /* Some course name patterns we don't expect would use the LMS. */
) enabledCourses ON enabledCourses.id = ed.course_id
LEFT JOIN (
	SELECT ed.user_id, count(*) AS count
	FROM canvas_data.pseudonym_dim p
	JOIN canvas_data.enrollment_dim ed ON p.user_id = ed.user_id 
	JOIN (
		SELECT DISTINCT id
		FROM canvas_data.course_dim
		WHERE workflow_state != 'deleted'
		AND enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id = 'FA16') 
		AND name NOT LIKE '%Dissertation%' /* Some course name patterns we don't expect would use the LMS. */
	) c ON c.id = ed.course_id
	JOIN (
		SELECT ed.course_id FROM
		(SELECT user_id, course_id FROM canvas_data.enrollment_dim WHERE type = 'StudentEnrollment') ed
		JOIN (SELECT DISTINCT user_id, course_id, real_user_id FROM canvas_data.requests) rq /* Selecting only relevant fields into a subquery table can improve performance, especially with requests. */
		ON rq.user_id = ed.user_id AND rq.course_id = ed.course_id 
		WHERE rq.real_user_id IS NULL 
		GROUP BY ed.course_id
	) studentAccess ON studentAccess.course_id = c.id
	LEFT JOIN (
		SELECT course_id,
		COUNT(DISTINCT assignment_id) AS assignments
		FROM canvas_data.assignment_fact
		WHERE enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id = 'FA16') /* While redundant with limitation in courses selected in subquery 'c', repeating it in content subqueries should improve performance. */
		GROUP BY course_id
	) a ON a.course_id = c.id
	LEFT JOIN (
		SELECT course_id,
		COUNT(DISTINCT discussion_topic_id) AS discussions
		FROM canvas_data.discussion_topic_fact
		WHERE enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id = 'FA16')
		GROUP BY course_id
	) d ON d.course_id = c.id
	LEFT JOIN (
		SELECT course_id,
		COUNT(DISTINCT file_id) AS files
		FROM canvas_data.file_fact
		WHERE enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id = 'FA16')
		GROUP BY course_id
	) f ON f.course_id = c.id
	LEFT JOIN (
		SELECT course_id,
		COUNT(DISTINCT quiz_id) AS quizzes
		FROM canvas_data.quiz_fact
		WHERE enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id = 'FA16')
		GROUP BY course_id
	) q ON q.course_id = c.id
	LEFT JOIN (
		SELECT parent_course_id,
		COUNT(DISTINCT wiki_page_id) AS wikis
		FROM canvas_data.wiki_page_fact
		WHERE enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id = 'FA16')
		GROUP BY parent_course_id
	) w ON w.parent_course_id = c.id
	GROUP BY ed.user_id
) activeFA16 on p.user_id = activeFA16.user_id
LEFT JOIN (
	SELECT ed.user_id, count(*) AS count
	FROM canvas_data.pseudonym_dim p
	JOIN canvas_data.enrollment_dim ed ON p.user_id = ed.user_id 
	JOIN (
		SELECT DISTINCT id
		FROM canvas_data.course_dim
		WHERE workflow_state != 'deleted'
		AND enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id = 'SP17') /
		AND name NOT LIKE '%Dissertation%' /* Some course name patterns we don't expect would use the LMS. */
	) c ON c.id = ed.course_id
	JOIN (
		SELECT ed.course_id FROM
		(SELECT user_id, course_id FROM canvas_data.enrollment_dim WHERE type = 'StudentEnrollment') ed
		JOIN (SELECT DISTINCT user_id, course_id, real_user_id FROM canvas_data.requests) rq /* Selecting only relevant fields into a subquery table can improve performance, especially with requests. */
		ON rq.user_id = ed.user_id AND rq.course_id = ed.course_id 
		WHERE rq.real_user_id IS NULL 
		GROUP BY ed.course_id
	) studentAccess ON studentAccess.course_id = c.id
	LEFT JOIN (
		SELECT course_id,
		COUNT(DISTINCT assignment_id) AS assignments
		FROM canvas_data.assignment_fact
		WHERE enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id = 'SP17') /* While redundant with limitation in courses selected in subquery 'c', repeating it in content subqueries should improve performance. */
		GROUP BY course_id
	) a ON a.course_id = c.id
	LEFT JOIN (
		SELECT course_id,
		COUNT(DISTINCT discussion_topic_id) AS discussions
		FROM canvas_data.discussion_topic_fact
		WHERE enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id = 'SP17')
		GROUP BY course_id
	) d ON d.course_id = c.id
	LEFT JOIN (
		SELECT course_id,
		COUNT(DISTINCT file_id) AS files
		FROM canvas_data.file_fact
		WHERE enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id = 'SP17')
		GROUP BY course_id
	) f ON f.course_id = c.id
	LEFT JOIN (
		SELECT course_id,
		COUNT(DISTINCT quiz_id) AS quizzes
		FROM canvas_data.quiz_fact
		WHERE enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id = 'SP17')
		GROUP BY course_id
	) q ON q.course_id = c.id
	LEFT JOIN (
		SELECT parent_course_id,
		COUNT(DISTINCT wiki_page_id) AS wikis
		FROM canvas_data.wiki_page_fact
		WHERE enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id = 'SP17')
		GROUP BY parent_course_id
	) w ON w.parent_course_id = c.id
	GROUP BY ed.user_id
) activeSP17 on p.user_id = activeSP17.user_id
LEFT JOIN (
	SELECT ed.user_id, count(*) AS count
	FROM canvas_data.enrollment_dim ed
	JOIN (
		SELECT DISTINCT id
		FROM canvas_data.course_dim
		WHERE workflow_state != 'deleted'
		AND enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id IN ('FA16','SP17')) /* Transition semesters */
		AND name NOT LIKE '%Dissertation%'
	) c ON c.id = ed.course_id
	WHERE ed.type = 'TeacherEnrollment'
	AND ed.workflow_state = 'active'
	GROUP BY ed.user_id
) transitionEnabledCount ON transitionEnabledCount.user_id = p.user_id 
LEFT JOIN (
	SELECT ed.user_id, count(*) AS count
	FROM canvas_data.enrollment_dim ed
	JOIN (
		SELECT DISTINCT id
		FROM canvas_data.course_dim
		WHERE workflow_state != 'deleted'
		AND enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id = 'FA17') /* First post-transition semester */
		AND name NOT LIKE '%Dissertation%'
	) c ON c.id = ed.course_id
	WHERE ed.type = 'TeacherEnrollment'
	AND ed.workflow_state = 'active'
	GROUP BY ed.user_id
) fa17enabledCount ON fa17enabledCount.user_id = p.user_id 
WHERE ed.type = 'TeacherEnrollment'
AND ed.workflow_state = 'active'
/*AND p.integration_id NOT IN () --administrative users excluded */
AND activeFA16.count IS NULL
AND activeSP17.count IS NULL
AND transitionEnabledCount.count IS NOT NULL
AND fa17enabledCount.count IS NOT NULL
GROUP BY p.integration_id, p.last_request_at;
