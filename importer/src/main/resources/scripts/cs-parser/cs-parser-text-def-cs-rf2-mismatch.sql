/******************************************************************************** 
	cs-parser-text-def-cs-rf2-mismatch
	Assertion:
	Textdef that has different results in change set compared to Rf2.

********************************************************************************/
	drop table if exists v_allid;
	drop table if exists v_newid;
	drop table if exists v_maxidtime;
	drop table if exists v_maxcs_description;
	drop table if exists v_mismatching;


	-- All distinct ids in CS
	create table if not exists v_allid as
	select distinct(id) 
	from cs_description
	where type_uuid ='00791270-77c9-32b6-b34f-d932569bd2bf';


	-- SCTids that new to current release
	create table if not exists v_newid as
	select a.* from v_allid a
	left join prev_textdefinition_s b 
	on a.id = b.id
	where b.id is null;

	-- Map all ids to latest committime
	create table if not exists v_maxidtime as
	select id, max(committime) as committime 
	from cs_description
	where type_uuid = '00791270-77c9-32b6-b34f-d932569bd2bf'
	group by id; 

	-- Descriptions that were created in current release but were then inactivated
	create table if not exists v_maxcs_description as
	select a.* 
	from cs_description a, v_maxidtime b
	where a.id = b.id 
	and a.committime = b.committime;

	create table if not exists v_mismatching as
	select a.id, a.description_uuid,
			a.active as cs_active, 
			a.conceptid as cs_conceptid,
			a.languagecode as cs_languagecode,
			a.typeid as cs_typeid,
			a.term as cs_term,
			a.casesignificanceid as cs_casesignificanceid,
			b.active as rf2_active, 
			b.conceptid as rf2_conceptid,
			b.languagecode as rf2_languagecode,
			b.typeid as rf2_typeid,
			b.term as rf2_term,
			b.casesignificanceid as rf2_casesignificanceid
	from v_maxcs_description a 
	inner join curr_textdefinition_d b 
	on a.id = b.id 
	where a.active != b.active 
	or a.conceptid != b.conceptid
	or a.languagecode != b.languagecode
	or a.typeid != b.typeid
	or a.term != b.term
	or a.casesignificanceid != b.casesignificanceid;



	insert into qa_result (runid, assertionuuid, assertiontext, details)
	select 
		<RUNID>,
		'<ASSERTIONUUID>',
		'<ASSERTIONTEXT>',
		concat('TextDef: id=',id, ': Textdef that has different results in change set compared to Rf2.') 
	from v_mismatching;
	
