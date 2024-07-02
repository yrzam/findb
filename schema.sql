CREATE TABLE "balance_goals" (
	"id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL,
	"asset_storage_id"	INTEGER NOT NULL,
	"amount"	REAL NOT NULL,
	"priority"	INTEGER NOT NULL UNIQUE,
	"deadline"	TEXT CHECK("deadline" IS datetime("deadline")),
	"result_transaction_id"	INTEGER,
	"start_datetime"	TEXT NOT NULL CHECK("start_datetime" IS datetime("start_datetime")),
	"end_datetime"	TEXT CHECK("end_datetime" IS datetime("end_datetime")),
	FOREIGN KEY("result_transaction_id") REFERENCES "fin_transactions"("id"),
	PRIMARY KEY("id"),
	FOREIGN KEY("asset_storage_id") REFERENCES "fin_assets_storages"("id")
);
	
CREATE TABLE "balances" (
	"id"	INTEGER NOT NULL,
	"datetime"	TEXT NOT NULL CHECK("datetime" IS datetime("datetime")),
	"asset_storage_id"	INTEGER NOT NULL,
	"amount"	REAL NOT NULL,
	FOREIGN KEY("asset_storage_id") REFERENCES "fin_assets_storages"("id"),
	UNIQUE("datetime","asset_storage_id"),
	PRIMARY KEY("id")
);
	
CREATE TABLE "fin_allocation_groups" (
	"id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL,
	"target_share"	REAL NOT NULL DEFAULT 0,
	"start_datetime"	TEXT NOT NULL CHECK("start_datetime" IS datetime("start_datetime")),
	"end_datetime"	TEXT CHECK("end_datetime" IS datetime("end_datetime")),
	"priority"	INTEGER UNIQUE,
	PRIMARY KEY("id")
);
	
CREATE TABLE "fin_asset_rates" (
	"id"	INTEGER NOT NULL,
	"datetime"	TEXT NOT NULL CHECK(datetime is datetime(datetime)),
	"asset_id"	INTEGER NOT NULL,
	"rate"	REAL NOT NULL,
	FOREIGN KEY("asset_id") REFERENCES "fin_assets"("id"),
	UNIQUE("datetime","asset_id"),
	PRIMARY KEY("id")
);
	
CREATE TABLE "fin_asset_types" (
	"id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id")
);
	
CREATE TABLE "fin_assets" (
	"id"	INTEGER NOT NULL,
	"code"	TEXT NOT NULL CHECK(code is upper(code) and (code like '% %') is not 1),
	"name"	TEXT,
	"description"	TEXT,
	"type_id"	INTEGER NOT NULL,
	"is_base"	INTEGER NOT NULL DEFAULT 0,
	"is_active"	INTEGER NOT NULL DEFAULT 1,
	FOREIGN KEY("type_id") REFERENCES "fin_asset_types"("id"),
	UNIQUE("type_id","code"),
	PRIMARY KEY("id")
);
	
CREATE TABLE "fin_assets_storages" (
	"id"	INTEGER NOT NULL,
	"asset_id"	INTEGER NOT NULL,
	"storage_id"	INTEGER NOT NULL,
	"priority"	INTEGER UNIQUE,
	"allocation_group_id"	INTEGER,
	FOREIGN KEY("asset_id") REFERENCES "fin_assets"("id"),
	FOREIGN KEY("allocation_group_id") REFERENCES "fin_allocation_groups"("id"),
	FOREIGN KEY("storage_id") REFERENCES "fin_storages"("id"),
	PRIMARY KEY("id"),
	UNIQUE("asset_id","storage_id")
);
	
CREATE TABLE "fin_storages" (
	"id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL UNIQUE,
	"description"	TEXT,
	"is_active"	INTEGER NOT NULL DEFAULT 1,
	PRIMARY KEY("id")
);
	
CREATE TABLE "fin_transaction_categories" (
	"id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL UNIQUE,
	"is_passive"	INTEGER CHECK(is_passive is null or is_initial_import is null),
	"is_initial_import"	INTEGER CHECK(is_passive is null or is_initial_import is null),
	"parent_id"	INTEGER,
	"min_view_depth"	INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY("id"),
	FOREIGN KEY("parent_id") REFERENCES "fin_transaction_categories"("id")
);
	
CREATE TABLE "fin_transaction_plans" (
	"id"	INTEGER NOT NULL,
	"transaction_category_id"	INTEGER NOT NULL,
	"criteria_operator"	TEXT NOT NULL CHECK("criteria_operator" IN ('<', '>', '=', '<=', '>=')),
	"start_datetime"	TEXT NOT NULL CHECK("start_datetime" IS datetime("start_datetime")),
	"end_datetime"	TEXT CHECK("end_datetime" IS datetime("end_datetime")),
	"recurrence_datetime_modifiers"	TEXT,
	"recurrence_amount_multiplier"	REAL,
	"deviation_datetime_modifier"	TEXT NOT NULL,
	"asset_storage_id"	INTEGER CHECK(NOT ("asset_storage_id" IS null AND "local_amount" IS NOT null)),
	"local_amount"	REAL CHECK(NOT ("asset_storage_id" IS null AND "local_amount" IS NOT null) AND coalesce("base_amount", "local_amount") IS NOT null AND "base_amount" + "local_amount" IS null),
	"base_amount"	REAL CHECK(coalesce("base_amount", "local_amount") IS NOT null AND "base_amount" + "local_amount" IS null),
	PRIMARY KEY("id"),
	FOREIGN KEY("transaction_category_id") REFERENCES "fin_transaction_categories"("id"),
	FOREIGN KEY("asset_storage_id") REFERENCES "fin_assets_storages"("id")
);
	
CREATE TABLE "fin_transactions" (
	"id"	INTEGER NOT NULL,
	"datetime"	TEXT NOT NULL CHECK("datetime" IS datetime("datetime")),
	"description"	TEXT,
	"asset_storage_id"	INTEGER NOT NULL,
	"amount"	REAL NOT NULL CHECK(amount is not 0),
	"category_id"	INTEGER NOT NULL,
	"reason_fin_asset_storage_id"	INTEGER CHECK(NOT ("reason_fin_asset_storage_id" IS NOT null AND "reason_phys_asset_ownership_id" IS NOT null)),
	"reason_phys_asset_ownership_id"	INTEGER CHECK(NOT ("reason_fin_asset_storage_id" IS NOT null AND "reason_phys_asset_ownership_id" IS NOT null)),
	FOREIGN KEY("category_id") REFERENCES "fin_transaction_categories"("id"),
	FOREIGN KEY("reason_fin_asset_storage_id") REFERENCES "fin_assets_storages"("id"),
	FOREIGN KEY("reason_phys_asset_ownership_id") REFERENCES "phys_asset_ownerships"("id"),
	PRIMARY KEY("id")
);
	
CREATE TABLE "phys_asset_ownerships" (
	"id"	INTEGER NOT NULL,
	"asset_id"	INTEGER NOT NULL,
	"start_datetime"	TEXT NOT NULL CHECK("start_datetime" IS datetime("start_datetime")),
	"end_datetime"	TEXT CHECK("end_datetime" IS datetime("end_datetime")),
	PRIMARY KEY("id"),
	FOREIGN KEY("asset_id") REFERENCES "phys_assets"("id")
);
	
CREATE TABLE "phys_assets" (
	"id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL UNIQUE,
	"description"	TEXT,
	PRIMARY KEY("id")
);
	
CREATE TABLE "swaps" (
	"id"	INTEGER NOT NULL,
	"credit_fin_transaction_id"	INTEGER UNIQUE,
	"credit_phys_ownership_id"	INTEGER UNIQUE,
	"debit_fin_transaction_id"	INTEGER UNIQUE,
	"debit_phys_ownership_id"	INTEGER UNIQUE,
	FOREIGN KEY("debit_phys_ownership_id") REFERENCES "phys_asset_ownerships"("id"),
	FOREIGN KEY("debit_fin_transaction_id") REFERENCES "fin_transactions"("id"),
	FOREIGN KEY("credit_fin_transaction_id") REFERENCES "fin_transactions"("id"),
	FOREIGN KEY("credit_phys_ownership_id") REFERENCES "phys_asset_ownerships"("id"),
	PRIMARY KEY("id")
);
	
CREATE INDEX "i_balance_goals_asset_storage_id" ON "balance_goals" (
	"asset_storage_id"
);
	
CREATE INDEX "i_balance_goals_end_datetime_part_no_result" ON "balance_goals" (
	"end_datetime"	DESC
) WHERE "result_transaction_id" IS NOT null;
	
CREATE INDEX "i_balance_goals_result_transaction_id" ON "balance_goals" (
	"result_transaction_id"
);
	
CREATE INDEX "i_balances_asset_storage_id_datetime" ON "balances" (
	"asset_storage_id",
	"datetime"	DESC
);
	
CREATE INDEX "i_fin_allocation_groups_end_datetime" ON "fin_allocation_groups" (
	"end_datetime"	DESC
);
	
CREATE INDEX "i_fin_asset_rates_asset_id_datetime" ON "fin_asset_rates" (
	"asset_id",
	"datetime"	DESC
);
	
CREATE INDEX "i_fin_assets_is_base" ON "fin_assets" (
	"is_base"
);
	
CREATE INDEX "i_fin_assets_storages_allocation_group_id" ON "fin_assets_storages" (
	"allocation_group_id"
);
	
CREATE INDEX "i_fin_assets_storages_asset_id" ON "fin_assets_storages" (
	"asset_id"
);
	
CREATE INDEX "i_fin_assets_storages_storage_id" ON "fin_assets_storages" (
	"storage_id"
);
	
CREATE INDEX "i_fin_assets_type_id" ON "fin_assets" (
	"type_id"
);
	
CREATE INDEX "i_fin_transaction_categories_parent_id" ON "fin_transaction_categories" (
	"parent_id"
);
	
CREATE INDEX "i_fin_transactions_asset_storage_id_datetime" ON "fin_transactions" (
	"asset_storage_id",
	"datetime"	DESC
);
	
CREATE INDEX "i_fin_transactions_category_id" ON "fin_transactions" (
	"category_id"
);
	
CREATE INDEX "i_fin_transactions_datetime" ON "fin_transactions" (
	"datetime"	DESC
);
	
CREATE INDEX "i_fin_transactions_reason_phys_asset_ownership_id" ON "fin_transactions" (
	"reason_phys_asset_ownership_id"
);
	
CREATE INDEX "i_fin_transactions_result_fin_asset_storage_id" ON "fin_transactions" (
	"reason_fin_asset_storage_id"
);
	
CREATE INDEX "i_phys_asset_ownerships_asset_id_end_datetime" ON "phys_asset_ownerships" (
	"asset_id",
	"end_datetime"	DESC
);
	
CREATE TRIGGER fin_transaction_categories_insert after insert on fin_transaction_categories
begin
with recursive
parents(parent_id) as (
	values(new.parent_id)
	union
	select
		cat.parent_id
	from
		parents p
		join fin_transaction_categories cat on cat.id=p.parent_id
	where
		cat.id!=new.id
)
select
	case
		when new.parent_id is null and exists(select 1 from fin_transaction_categories where parent_id is null and id!=new.id)
			then raise(abort, 'root of the hierarchy already exists')
		when not exists(select 1 from parents where parent_id is null)
			then raise(abort, 'upper part of the hierarchy is circular')
		when exists(
			select
				1
			from
				fin_transaction_categories p
			where
				p.id=new.parent_id and
				(
					not (p.is_passive is null or p.is_passive is new.is_passive) or
					not (p.is_initial_import is null or p.is_initial_import is new.is_initial_import)
				)
			)
			then raise(abort, 'parent conditions not met')
		when exists(
			select
				1
			from
				fin_transaction_categories c
			where
				c.parent_id=new.id and
				(
					not(new.is_passive is null or new.is_passive is c.is_passive) or
					not(new.is_initial_import is null or new.is_initial_import=c.is_initial_import)
				)
			)
			then raise(abort, 'child conditions not met')
	end;
end;
	
CREATE TRIGGER fin_transaction_categories_update after update of id,parent_id,is_passive,is_initial_import on fin_transaction_categories
begin
with recursive
parents(parent_id) as (
	values(new.parent_id)
	union
	select
		cat.parent_id
	from
		parents p
		join fin_transaction_categories cat on cat.id=p.parent_id
	where
		cat.id!=new.id
)
select
	case
		when new.parent_id is null and exists(select 1 from fin_transaction_categories where parent_id is null and id!=new.id)
			then raise(abort, 'root of the hierarchy already exists')
		when not exists(select 1 from parents where parent_id is null)
			then raise(abort, 'upper part of the hierarchy is circular')
		when exists(
			select
				1
			from
				fin_transaction_categories p
			where
				p.id=new.parent_id and
				(
					not (p.is_passive is null or p.is_passive is new.is_passive) or
					not (p.is_initial_import is null or p.is_initial_import is new.is_initial_import)
				)
			)
			then raise(abort, 'parent conditions not met')
		when exists(
			select
				1
			from
				fin_transaction_categories c
			where
				c.parent_id=new.id and
				(
					not(new.is_passive is null or new.is_passive is c.is_passive) or
					not(new.is_initial_import is null or new.is_initial_import=c.is_initial_import)
				)
			)
			then raise(abort, 'child conditions not met')
	end;
end;
	
CREATE VIEW "current_balance_goals" AS select
	t.amount_left=0 as is_accomplished,
	t.goal,
	t.storage,
	t.amount_total,
	t.amount_left,
	case when t.amount_left!=0 then t.deadline end as deadline
from (
	select
		bg.name as goal,
		coalesce(fa.name,fa.code)||' - '||fs.name as storage,
		bg.amount as amount_total,
		bg.priority,
		bg.deadline,
		min(max(
			sum(bg.amount) over(
				partition by
					bg.asset_storage_id
				order by
					bg.priority desc
				rows between 
					unbounded preceding and current row
			) - coalesce((
				select 
					amount
				from 
					balances b 
				where 
					b.asset_storage_id=bg.asset_storage_id and
					b.datetime<=datetime('now')
				order by
					b.datetime desc
				limit 1
			),0),
			0
		), bg.amount) as amount_left
	from
		balance_goals bg
		join fin_assets_storages fas on fas.id=bg.asset_storage_id
		join fin_assets fa on fa.id=fas.asset_id
		join fin_storages fs on fs.id=fas.storage_id
	where
		bg.result_transaction_id is null and
		(
			datetime('now')>=bg.start_datetime and
			(datetime('now')<bg.end_datetime or bg.end_datetime is null)
		)
) t
order by 
	is_accomplished asc,
	t.priority desc;
	
CREATE VIEW "current_balances" AS select
	*
from (
	select
		fas.id as pseudo_id,
		fat.name as asset_type,
		coalesce(fa.code,fa.name) as asset_name,
		fs.name  as storage,
		(select b.amount from balances b where b.asset_storage_id=fas.id and b.datetime<=datetime('now') order by b.datetime desc limit 1) as balance,
		fa.code as asset_code,
		round(
			(select b.amount from balances b where b.asset_storage_id=fas.id and b.datetime<=datetime('now') order by b.datetime desc limit 1)*
			(select far.rate from fin_asset_rates far where far.asset_id=fa.id and far.datetime<=datetime('now') order by far.datetime desc limit 1),
		2) as base_balance,
		(select code from fin_assets fa2 where fa2.is_base limit 1) as base_asset
	from
		fin_assets_storages fas
		join fin_assets fa on fa.id=fas.asset_id
		join fin_asset_types fat on fat.id=fa.type_id
		join fin_storages fs on fs.id=fas.storage_id
	where
		fa.is_active and
		fs.is_active
	order by
		fas.priority desc
) t
where 
	t.balance is not null;
	
CREATE VIEW current_fin_allocation as 
select 
	t.name as "group",
	round(t.base_balance,2) as base_balance,
	(select code from fin_assets fa2 where fa2.is_base limit 1) as base_asset,
	(round(t.current_share, 1) || '%') as current_share,
	(round(t.target_share, 1)  || '%') as target_share
from (
		select
			t.name,
			t.base_balance,
			t.base_balance*100 / sum(abs(t.base_balance)) over() as current_share,
			t.target_share,
			1 as sort1,
			t.priority
		from
			(
				select
					fag.name,
					fag.priority,
					coalesce(
						sum(
							(select b.amount from balances b where b.asset_storage_id=fas.id and b.datetime<=datetime('now') order by b.datetime desc limit 1)*
							(select far.rate from fin_asset_rates far where far.asset_id=fa.id and far.datetime<=datetime('now') order by far.datetime desc limit 1)
						),
					0) as base_balance,
					fag.target_share * 100 / sum(abs(fag.target_share)) over () as target_share
				from
					fin_allocation_groups fag
					left join fin_assets_storages fas on fas.allocation_group_id=fag.id
					left join fin_assets fa on fa.id=fas.asset_id
					left join fin_storages fs on fs.id=fas.storage_id
				where
					(
						date('now')>=fag.start_datetime and
						(date('now')<fag.end_datetime or fag.end_datetime is null)
					) and
					(
						fas.id is null or 
						(fa.is_active and fs.is_active)
					)
				group by 
					fag.id
			) t
	union all
		select
			'Others' as name,
			sum(
				(select b.amount from balances b where b.asset_storage_id=fas.id and b.datetime<=datetime('now') order by b.datetime desc limit 1)*
				(select far.rate from fin_asset_rates far where far.asset_id=fa.id and far.datetime<=datetime('now') order by far.datetime desc limit 1)
			) as base_balance,
			null as current_share,
			null as target_share,
			0 as sort1,
			null as priority
		from
			fin_assets_storages fas
			join fin_assets fa on fa.id=fas.asset_id
			join fin_storages fs on fs.id=fas.storage_id
		where
			fas.allocation_group_id is null and
			fa.is_active and
			fs.is_active
) t
where
	t.base_balance!=0 or t.target_share!=0
order by
	sort1 desc,
	priority desc;
	
CREATE VIEW "current_fin_asset_rates" as
select
	fa.id as pseudo_id,
	fat.name as asset_type,
	fa.code as asset,
	(select rate from fin_asset_rates far where far.asset_id=fa.id and far.datetime<=datetime('now') order by far.datetime desc limit 1) as rate,
	(select fa2.code from fin_assets fa2 where fa2.is_base limit 1) as base_asset
from
	fin_assets fa
	join fin_asset_types fat on fat.id=fa.type_id
where
	fa.is_active;
	
CREATE VIEW historical_monthly_balances as
with recursive
datetimes(start_datetime, end_datetime) as materialized (
	select
		datetime('now','start of month') as start_datetime,
		datetime('now','start of month','+1 month','-1 second') as end_datetime
	union all
	select
		datetime(start_datetime,'-1 month') as start_datetime,
		datetime(start_datetime,'-1 second') as end_datetime
	from
		datetimes
	where
		start_datetime>=(select min(datetime) from balances)
	limit 5*12
),
constants as(
	select
		(select code from fin_assets fa2 where fa2.is_base limit 1) as base_asset
),
data_by_asset as materialized (
	select
		b.start_datetime,
		b.end_datetime,
		b.asset_id,
		(select far.rate from fin_asset_rates far where far.asset_id=b.asset_id and far.datetime<=b.end_datetime order by far.datetime desc limit 1) as end_asset_rate,
		b.balance as balance,
		coalesce(tx.total_delta,0) as tx_total_delta,
		coalesce(tx.active_delta,0) as tx_active_delta,
		coalesce(tx.base_excluded_delta,0) as base_tx_excluded_delta
	from
		( -- balances by asset
			select
				d.start_datetime,
				d.end_datetime,
				fas.asset_id,
				sum(
					(select b.amount from balances b where b.asset_storage_id=fas.id and b.datetime<=d.end_datetime order by b.datetime desc limit 1)
				) as balance
			from
				datetimes d,
				fin_assets_storages fas
			group by
				1,2,3
		) b
		left join ( -- txs by asset
			select
				d.start_datetime,
				d.end_datetime,
				fas.asset_id,
				sum(ft.amount) as total_delta,
				sum(ft.amount) filter(where not ftc.is_passive and not ftc.is_initial_import and s.id is null) as active_delta,
				(	-- exclude txs:
					-- 1) initial import
					coalesce(
						sum(
							ft.amount*
							(select far.rate from fin_asset_rates far where far.asset_id=fas.asset_id and far.datetime<=ft.datetime order by far.datetime desc limit 1)
						)
						filter(where ftc.is_initial_import and s.id is null)
					,0) +
					-- 2) fin -> fin swap, counted by credit amount
					coalesce(
						sum(
							s_cred_ft.amount*
							(case when s.credit_fin_transaction_id=ft.id then 1 else -1 end)* -- if transaction is debit, take credit with the opposite sign
							(select far.rate from fin_asset_rates far where far.asset_id=s_cred_fas.asset_id and far.datetime<=ft.datetime order by far.datetime desc limit 1)
						)
						filter(where s.id is not null)
					,0)
				) as base_excluded_delta 
			from
				datetimes d
				join fin_transactions ft on ft.datetime>=d.start_datetime and ft.datetime<d.end_datetime -- < !!!
				join fin_assets_storages fas on fas.id=ft.asset_storage_id
				join fin_transaction_categories ftc on ftc.id=ft.category_id
				left join swaps s on (s.credit_fin_transaction_id=ft.id or s.debit_fin_transaction_id=ft.id) and (s.credit_fin_transaction_id is not null and s.debit_fin_transaction_id is not null) -- swap fin -> fin
				left join fin_transactions s_cred_ft on s_cred_ft.id=s.credit_fin_transaction_id
				left join fin_assets_storages s_cred_fas on s_cred_fas.id=s_cred_ft.asset_storage_id
			group by
				1,2,3
		) tx on tx.asset_id=b.asset_id and tx.start_datetime=b.start_datetime and tx.end_datetime=b.end_datetime
	where
		b.balance is not null
),
data_by_asset_type as materialized (
	select
		t.start_datetime,
		t.end_datetime,
		t.asset_type_id,
		coalesce(sum(t.balance*t.end_asset_rate),0) as base_balance,
		coalesce(sum(t.base_balance_delta),0) as base_balance_delta,
		coalesce(sum(t.tx_active_delta*t.end_asset_rate),0) as base_active_delta,
		coalesce(sum((t.balance_delta-t.tx_total_delta)*t.end_asset_rate+t.base_tx_excluded_delta),0) as base_unaccounted_delta
	from
	(
		select
			t.*,
			t.balance-coalesce(
				lead(t.balance) over(partition by t.asset_id order by t.end_datetime desc),
				0
			) as balance_delta,
			t.balance*t.end_asset_rate-coalesce(
				lead(t.balance*t.end_asset_rate) over(partition by t.asset_id order by t.end_datetime desc),
				0
			) as base_balance_delta,
			fa.type_id as asset_type_id
		from
			data_by_asset t
			join fin_assets fa on fa.id=t.asset_id
	) t
	group by
		1,2,3
)
select
	start_datetime,
	end_datetime,
	round(sum(t.base_balance),2) as base_balance,
	round(sum(t.base_balance_delta),2) as base_balance_delta,
	round(sum(t.base_active_delta),2) as base_active_delta,
	round(sum(t.base_balance_delta)-sum(t.base_active_delta)-sum(t.base_unaccounted_delta),2) as base_passive_delta,
	round(sum(t.base_unaccounted_delta),2) as base_unaccounted_delta,
	(select base_asset from constants) as base_asset,
	group_concat(fat.name||'='||cast(t.base_balance as integer) || ' ' || (select base_asset from constants), '; ') as base_balance_by_type,
	group_concat(fat.name||'='||cast(t.base_balance_delta as integer) || ' ' || (select base_asset from constants), '; ') as base_balance_delta_by_type,
	group_concat(fat.name||'='||cast(t.base_active_delta as integer) || ' ' || (select base_asset from constants), '; ') as base_active_delta_by_type,
	group_concat(fat.name||'='||cast(t.base_balance_delta-t.base_active_delta-t.base_unaccounted_delta as integer) || ' ' || (select base_asset from constants), '; ') as base_passive_delta_by_type,
	group_concat(fat.name||'='||cast(t.base_unaccounted_delta as integer) || ' ' || (select base_asset from constants), '; ') as base_unaccounted_delta_by_type
from
	data_by_asset_type t
	join fin_asset_types fat on fat.id=t.asset_type_id
group by
	1,2
order by
	t.end_datetime desc;
	
CREATE VIEW historical_txs_balances_mismatch as select
	t.start_datetime,
	t.end_datetime,
	fs.name as storage,
	abs(round(t.balance_delta - t.tx_delta,9)) as amount_unaccounted,
	coalesce(fa.code,fa.name) as asset,
	round(t.tx_delta,9) as tx_delta,
	round(t.balance_delta,9) as balance_delta
from 
	(
		select
			t.asset_storage_id,
			t.start_datetime,
			t.end_datetime,
			(t.end_amount-coalesce(t.start_amount,0)) as balance_delta,
			(
				select coalesce(sum(amount),0) 
				from
					fin_transactions ft
				where
					ft.asset_storage_id=t.asset_storage_id and
					ft.datetime<t.end_datetime and
					(
						ft.datetime>=t.start_datetime or
						t.start_datetime is null
					)
			) as tx_delta
		from (
			select
				t.*,
				(select b.amount from balances b where b.asset_storage_id=t.asset_storage_id and b.datetime<t.end_datetime order by b.datetime desc limit 1) as start_amount,
				(select b.datetime from balances b where b.asset_storage_id=t.asset_storage_id and b.datetime<t.end_datetime order by b.datetime desc limit 1) as start_datetime
			from ( -- >=1 row for each fas
						select
							b.asset_storage_id,
							b.amount as end_amount,
							b.datetime as end_datetime
						from
							balances b
						where
							b.datetime>=datetime('now', '-2 years')
					union
						select
							fas.id as asset_storage_id,
							coalesce(
								(select b.amount from balances b where b.asset_storage_id=fas.id and b.datetime<=datetime('now') order by b.datetime desc limit 1),
								0
							) as end_amount,
							datetime('now') as end_datetime
						from
							fin_assets_storages fas
			) t
		) t
	) t
	join fin_assets_storages fas on fas.id=t.asset_storage_id
	join fin_assets fa on fa.id=fas.asset_id
	join fin_storages fs on fs.id=fas.storage_id
where
	abs(t.tx_delta-t.balance_delta)>pow(10,-9)
order by
	asset,
	storage,
	start_datetime;
	
CREATE VIEW latest_fin_transactions as
select
	ft.id as pseudo_id,
	ft.datetime,
	fat.name as asset_type,
	coalesce(fa.name, fa.code) as asset_name,
	fs.name as storage,
	ft.amount,
	fa.code as asset_code,
	ftc.name as category,
	r_pa.name as reason_phys_asset,
	r_fat.name as reason_fin_asset_type,
	r_fa.code as reason_fin_asset_code,
	r_fs.name as reason_fin_asset_storage,
	cast(null as int) as adjust_balance
from
	fin_transactions ft
	join fin_transaction_categories ftc on ftc.id=ft.category_id
	join fin_assets_storages fas on fas.id=ft.asset_storage_id
	join fin_assets fa on fa.id=fas.asset_id
	join fin_asset_types fat on fat.id=fa.type_id
	join fin_storages fs on fs.id=fas.storage_id
	
	left join phys_asset_ownerships r_pao on r_pao.id=ft.reason_phys_asset_ownership_id
	left join phys_assets r_pa on r_pa.id=r_pao.asset_id
	left join fin_assets_storages r_fas on r_fas.id=ft.reason_fin_asset_storage_id
	left join fin_assets r_fa on r_fa.id=r_fas.asset_id
	left join fin_asset_types r_fat on r_fat.id=r_fa.type_id
	left join fin_storages r_fs on r_fs.id=r_fas.storage_id
order by
	ft.datetime desc,
	ft.id desc;
	
CREATE TRIGGER current_balances_insert
instead of insert on current_balances
begin
	insert into fin_assets_storages(asset_id, storage_id)
	values(
		(select fa.id from fin_assets fa join fin_asset_types fat on fat.id=fa.type_id where fa.code=new.asset_code and fat.name=new.asset_type),
		(select id from fin_storages where name=new.storage)
	)
	on conflict do nothing;
	insert into balances(asset_storage_id, datetime, amount)
	values(
		(
			select
				fas.id
			from
				fin_assets_storages fas
				join fin_assets fa on fa.id=fas.asset_id
				join fin_asset_types fat on fat.id=fa.type_id
				join fin_storages fs on fs.id=fas.storage_id
			where
				fa.code = new.asset_code and
				fat.name = new.asset_type and
				fs.name = new.storage
		),
		datetime('now'),
		new.balance
	)
	on conflict(asset_storage_id, datetime) do update
	set 
		amount = new.balance;
end;
	
CREATE TRIGGER current_balances_update
instead of update of balance on current_balances
begin
	insert into fin_assets_storages(asset_id, storage_id)
	values(
		(select fa.id from fin_assets fa join fin_asset_types fat on fat.id=fa.type_id where fa.code=new.asset_code and fat.name=new.asset_type),
		(select id from fin_storages where name=new.storage)
	)
	on conflict do nothing;
	insert into balances(asset_storage_id, datetime, amount)
	values(
		(
			select
				fas.id
			from
				fin_assets_storages fas
				join fin_assets fa on fa.id=fas.asset_id
				join fin_asset_types fat on fat.id=fa.type_id
				join fin_storages fs on fs.id=fas.storage_id
			where
				fa.code = new.asset_code and
				fat.name = new.asset_type and
				fs.name = new.storage
		),
		datetime('now'),
		new.balance
	)
	on conflict(asset_storage_id, datetime) do update
	set 
		amount = new.balance;
end;
	
CREATE TRIGGER current_fin_asset_rates_insert
instead of insert on current_fin_asset_rates
begin
	insert into fin_asset_rates (asset_id, datetime, rate)
	values(
		(
			select
				fa.id
			from 
				fin_assets fa
				join fin_asset_types fat on fat.id=fa.type_id
			where
				fa.code=new.asset and
				fat.name=new.asset_type
		),
		datetime('now'),
		new.rate
	)
	on conflict(asset_id,datetime) do update 
	set rate=new.rate;
end;
	
CREATE TRIGGER current_fin_asset_rates_update
instead of update of rate on current_fin_asset_rates
begin
	insert into fin_asset_rates (asset_id, datetime, rate)
	values(
		(
			select
				fa.id
			from 
				fin_assets fa
				join fin_asset_types fat on fat.id=fa.type_id
			where
				fa.code=new.asset and
				fat.name=new.asset_type
		),
		datetime('now'),
		new.rate
	)
	on conflict(asset_id,datetime) do update 
	set rate=new.rate;
end;
	
CREATE TRIGGER latest_fin_transactions_delete instead of delete on latest_fin_transactions
begin
	delete from
		fin_transactions
	where
		id=old.pseudo_id;
end;
	
CREATE TRIGGER latest_fin_transactions_insert
instead of insert on latest_fin_transactions
begin
	insert into fin_assets_storages(asset_id, storage_id)
	values(
		(select fa.id from fin_assets fa join fin_asset_types fat on fat.id=fa.type_id where fa.code=new.asset_code and fat.name=new.asset_type),
		(select id from fin_storages where name=new.storage)
	)
	on conflict do nothing;
	insert into fin_transactions(datetime, asset_storage_id, amount, category_id, reason_fin_asset_storage_id, reason_phys_asset_ownership_id)
	values(
		coalesce(new.datetime, datetime('now')),
		(
			select
				fas.id
			from
				fin_assets_storages fas
				join fin_assets fa on fa.id=fas.asset_id
				join fin_asset_types fat on fat.id=fa.type_id
				join fin_storages fs on fs.id=fas.storage_id
			where
				fa.code = new.asset_code and
				fat.name = new.asset_type and
				fs.name = new.storage
		),
		new.amount,
		(select id from fin_transaction_categories where name=new.category),
		(
			select
				fas.id
			from
				fin_assets_storages fas
				join fin_assets fa on fa.id=fas.asset_id
				join fin_asset_types fat on fat.id=fa.type_id
				join fin_storages fs on fs.id=fas.storage_id
			where
				fa.code = new.reason_fin_asset_code and
				fat.name = new.reason_fin_asset_type and
				fs.name = new.reason_fin_asset_storage
		),
		(
			select
				pao.id
			from
				phys_assets pa
				join phys_asset_ownerships pao on pao.asset_id=pa.id
			where
				pa.name=new.reason_phys_asset and
				(
					coalesce(new.datetime, datetime('now'))>=pao.start_datetime and
					(coalesce(new.datetime, datetime('now'))<pao.end_datetime or pao.end_datetime is null)
				)
		)
	);
	select
		case
			when coalesce(new.datetime, datetime('now'))!=datetime('now') and new.adjust_balance
			then raise(abort, 'adjust_balance works only with current date')
		end;
	insert into balances(datetime, asset_storage_id, amount)
	select
		datetime('now','+1 second') as datetime,
		fas.id as asset_storage_id,
		coalesce(
			(select b.amount from balances b where b.asset_storage_id=fas.id and b.datetime<=datetime('now') order by b.datetime desc limit 1),
			0
		)+new.amount as amount
	from
		fin_assets_storages fas
		join fin_assets fa on fa.id=fas.asset_id
		join fin_asset_types fat on fat.id=fa.type_id
		join fin_storages fs on fs.id=fas.storage_id
	where
		new.adjust_balance and
		fa.code = new.asset_code and
		fat.name = new.asset_type and
		fs.name = new.storage
	on conflict(datetime, asset_storage_id) do update
	set 
		amount = amount + new.amount;
end;
	
CREATE TRIGGER latest_fin_transactions_update
instead of update of datetime, asset_type, storage, amount, asset_code, category, reason_phys_asset, reason_fin_asset_type, reason_fin_asset_code, reason_fin_asset_storage on latest_fin_transactions
begin
	insert into fin_assets_storages(asset_id, storage_id)
	values(
		(select fa.id from fin_assets fa join fin_asset_types fat on fat.id=fa.type_id where fa.code=new.asset_code and fat.name=new.asset_type),
		(select id from fin_storages where name=new.storage)
	)
	on conflict do nothing;
	update 
		fin_transactions
	set
		datetime = new.datetime,
		asset_storage_id = (
				select
					fas.id
				from
					fin_assets_storages fas
					join fin_assets fa on fa.id=fas.asset_id
					join fin_asset_types fat on fat.id=fa.type_id
					join fin_storages fs on fs.id=fas.storage_id
				where
					fa.code = new.asset_code and
					fat.name = new.asset_type and
					fs.name = new.storage
			),
		amount = new.amount,
		category_id = (select id from fin_transaction_categories where name=new.category),
		reason_fin_asset_storage_id = (
				select
					fas.id
				from
					fin_assets_storages fas
					join fin_assets fa on fa.id=fas.asset_id
					join fin_asset_types fat on fat.id=fa.type_id
					join fin_storages fs on fs.id=fas.storage_id
				where
					fa.code = new.reason_fin_asset_code and
					fat.name = new.reason_fin_asset_type and
					fs.name = new.reason_fin_asset_storage
			),
		reason_phys_asset_ownership_id = (
			select
				pao.id
			from
				phys_assets pa
				join phys_asset_ownerships pao on pao.asset_id=pa.id
			where
				pa.name=new.reason_phys_asset and
				(
					coalesce(new.datetime, datetime('now'))>=pao.start_datetime and
					(coalesce(new.datetime, datetime('now'))<pao.end_datetime or pao.end_datetime is null)
				)
		)
	where
		id=new.pseudo_id;
	select
		case
			when new.adjust_balance
			then raise(abort, 'adjust_balance does not work with updates')
		end;
end;
	
