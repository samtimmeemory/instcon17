/**************************/
/**** THE NEW ADOPTERS ****/
/****    SAM TIMME     ****/
/**** EMORY UNIVERSITY ****/
/**** INSTRUCTURECON17 ****/
/**************************/

SELECT pd.integration_id as publicPersonID, /* sis_user_id or unique_name (which is login ID) may be more useful for you */
count(*) as count
FROM canvas_data.pseudonym_dim pd
JOIN canvas_data.enrollment_dim ed ON ed.user_id = pd.user_id
JOIN (
	SELECT DISTINCT id
	FROM canvas_data.course_dim
	WHERE workflow_state != 'deleted'
	AND enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id IN ('FA15CP','SP16CP','SU16C','FA16','SP17')) /* Semesters from pilot and transition years */
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
	WHERE enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id IN ('FA15CP','SP16CP','SU16C','FA16','SP17')) /* While redundant with limitation in courses selected in subquery 'c', repeating it in content subqueries should improve performance. */
	GROUP BY course_id
) a ON a.course_id = c.id
LEFT JOIN (
	SELECT course_id,
	COUNT(DISTINCT discussion_topic_id) AS discussions
	FROM canvas_data.discussion_topic_fact
	WHERE enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id IN ('FA15CP','SP16CP','SU16C','FA16','SP17'))
	GROUP BY course_id
) d ON d.course_id = c.id
LEFT JOIN (
	SELECT course_id,
	COUNT(DISTINCT file_id) AS files
	FROM canvas_data.file_fact
	WHERE enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id IN ('FA15CP','SP16CP','SU16C','FA16','SP17'))
	GROUP BY course_id
) f ON f.course_id = c.id
LEFT JOIN (
	SELECT course_id,
	COUNT(DISTINCT quiz_id) AS quizzes
	FROM canvas_data.quiz_fact
	WHERE enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id IN ('FA15CP','SP16CP','SU16C','FA16','SP17'))
	GROUP BY course_id
) q ON q.course_id = c.id
LEFT JOIN (
	SELECT parent_course_id,
	COUNT(DISTINCT wiki_page_id) AS wikis
	FROM canvas_data.wiki_page_fact
	WHERE enrollment_term_id IN (SELECT id FROM canvas_data.enrollment_term_dim WHERE sis_source_id IN ('FA15CP','SP16CP','SU16C','FA16','SP17'))
	GROUP BY parent_course_id
) w ON w.parent_course_id = c.id
WHERE pd.integration_id IN (/*List of IDs from Non-Adopters of old LMS*/)
AND ed.workflow_state != 'deleted'
AND ed.type = 'TeacherEnrollment'
AND (a.assignments IS NOT NULL
  OR d.discussions IS NOT NULL
  OR f.files IS NOT NULL
  OR q.quizzes IS NOT NULL
  OR w.wikis IS NOT NULL) /* Some non-null value in the five content tables indicates the course is not empty. */
GROUP BY pd.integration_id 
ORDER BY count desc;
