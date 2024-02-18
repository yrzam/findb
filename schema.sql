CREATE TABLE "balance_goals" (
	"id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL,
	"asset_storage_id"	INTEGER NOT NULL,
	"amount"	NUMERIC NOT NULL,
	"priority"	INTEGER NOT NULL UNIQUE,
	"deadline"	NUMERIC,
	"result_transaction_id"	INTEGER,
	FOREIGN KEY("asset_storage_id") REFERENCES "fin_assets_storages"("id"),
	PRIMARY KEY("id"),
	FOREIGN KEY("result_transaction_id") REFERENCES "fin_transactions"("id")
);
CREATE TABLE "balances" (
	"id"	INTEGER NOT NULL,
	"date"	NUMERIC NOT NULL,
	"asset_storage_id"	INTEGER NOT NULL,
	"amount"	NUMERIC NOT NULL,
	UNIQUE("date","asset_storage_id"),
	FOREIGN KEY("asset_storage_id") REFERENCES "fin_assets_storages"("id"),
	PRIMARY KEY("id")
);
CREATE TABLE "fin_allocation_groups" (
	"id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL UNIQUE,
	"target_share"	NUMERIC NOT NULL DEFAULT 0,
	"start_date"	NUMERIC NOT NULL,
	"end_date"	INTEGER,
	"priority"	INTEGER UNIQUE,
	PRIMARY KEY("id")
);
CREATE TABLE "fin_asset_rates" (
	"id"	INTEGER NOT NULL,
	"date"	NUMERIC NOT NULL,
	"asset_id"	INTEGER NOT NULL,
	"rate"	NUMERIC NOT NULL,
	UNIQUE("date","asset_id"),
	PRIMARY KEY("id"),
	FOREIGN KEY("asset_id") REFERENCES "fin_assets"("id")
);
CREATE TABLE "fin_asset_types" (
	"id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL,
	PRIMARY KEY("id")
);
CREATE TABLE "fin_assets" (
	"id"	INTEGER NOT NULL,
	"code"	TEXT NOT NULL,
	"name"	TEXT,
	"description"	TEXT,
	"type_id"	INTEGER NOT NULL,
	"is_base"	INTEGER NOT NULL DEFAULT 0,
	"is_active"	INTEGER NOT NULL DEFAULT 1,
	UNIQUE("type_id","code"),
	FOREIGN KEY("type_id") REFERENCES "fin_asset_types"("id"),
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
	"is_passive"	INTEGER NOT NULL DEFAULT 0,
	"is_rebalance"	INTEGER NOT NULL DEFAULT 0,
	"is_initial_import"	INTEGER NOT NULL DEFAULT 0,
	"parent_id"	INTEGER,
	"min_view_depth"	INTEGER NOT NULL DEFAULT 0,
	FOREIGN KEY("parent_id") REFERENCES "fin_transaction_categories"("id"),
	PRIMARY KEY("id")
);
CREATE TABLE "fin_transactions" (
	"id"	INTEGER NOT NULL,
	"date"	NUMERIC NOT NULL,
	"description"	TEXT,
	"asset_storage_id"	INTEGER NOT NULL,
	"amount"	NUMERIC NOT NULL,
	"category_id"	INTEGER NOT NULL,
	"reason_fin_asset_storage_id"	INTEGER,
	"reason_phys_asset_ownership_id"	INTEGER,
	FOREIGN KEY("category_id") REFERENCES "fin_transaction_categories"("id"),
	FOREIGN KEY("reason_fin_asset_storage_id") REFERENCES "fin_assets_storages"("id"),
	FOREIGN KEY("reason_phys_asset_ownership_id") REFERENCES "phys_asset_ownerships"("id"),
	PRIMARY KEY("id")
);
CREATE TABLE "phys_asset_ownerships" (
	"id"	INTEGER NOT NULL,
	"asset_id"	INTEGER NOT NULL,
	"start_date"	NUMERIC NOT NULL,
	"end_date"	NUMERIC,
	"buy_fin_tx_id"	INTEGER,
	"sell_fin_tx_id"	INTEGER,
	FOREIGN KEY("sell_fin_tx_id") REFERENCES "fin_transactions"("id"),
	FOREIGN KEY("buy_fin_tx_id") REFERENCES "fin_transactions"("id"),
	FOREIGN KEY("asset_id") REFERENCES "phys_assets"("id"),
	PRIMARY KEY("id")
);
CREATE TABLE "phys_assets" (
	"id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL UNIQUE,
	"description"	TEXT,
	PRIMARY KEY("id")
);
CREATE INDEX "i_balance_goals_asset_storage_id" ON "balance_goals" (
	"asset_storage_id"
);
CREATE INDEX "i_balance_goals_result_phys_asset_id" ON "balance_goals" (
	"result_transaction_id"
);
CREATE INDEX "i_balances_asset_storage_id_date" ON "balances" (
	"asset_storage_id",
	"date"	DESC
);
CREATE INDEX "i_fin_allocation_groups_end_date" ON "fin_allocation_groups" (
	"end_date"	DESC
);
CREATE INDEX "i_fin_asset_rates_asset_id_date" ON "fin_asset_rates" (
	"asset_id",
	"date"	DESC
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
CREATE INDEX "i_fin_transactions_asset_storage_id_date" ON "fin_transactions" (
	"asset_storage_id",
	"date"	DESC
);
CREATE INDEX "i_fin_transactions_category_id" ON "fin_transactions" (
	"category_id"
);
CREATE INDEX "i_fin_transactions_date" ON "fin_transactions" (
	"date"	DESC
);
CREATE INDEX "i_fin_transactions_reason_phys_asset_ownership_id" ON "fin_transactions" (
	"reason_phys_asset_ownership_id"
);
CREATE INDEX "i_fin_transactions_result_fin_asset_storage_id" ON "fin_transactions" (
	"reason_fin_asset_storage_id"
);
CREATE INDEX "i_phys_asset_ownerships_asset_id_end_date" ON "phys_asset_ownerships" (
	"asset_id",
	"end_date"	DESC
);
CREATE INDEX "i_phys_asset_ownerships_buy_fin_tx_id" ON "phys_asset_ownerships" (
	"buy_fin_tx_id"
);
CREATE INDEX "i_phys_asset_ownerships_sell_fin_tx_id" ON "phys_asset_ownerships" (
	"sell_fin_tx_id"
);
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
					b.asset_storage_id=bg.asset_storage_id
				order by
					b.date desc
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
		bg.result_transaction_id is null
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
		(select b.amount from balances b where b.asset_storage_id=fas.id order by b.date desc limit 1) as balance,
		fa.code as asset_code,
		round(
			(select b.amount from balances b where b.asset_storage_id=fas.id order by b.date desc limit 1)*
			(select far.rate from fin_asset_rates far where far.asset_id=fa.id order by far.date desc limit 1),
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
			t.base_balance*100 / sum(t.base_balance) over() as current_share,
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
							(select b.amount from balances b where b.asset_storage_id=fas.id order by b.date desc limit 1)*
							(select far.rate from fin_asset_rates far where far.asset_id=fa.id order by far.date desc limit 1)
						),
					0) as base_balance,
					fag.target_share * 100 / sum(fag.target_share) over () as target_share
				from
					fin_allocation_groups fag
					left join fin_assets_storages fas on fas.allocation_group_id=fag.id
					left join fin_assets fa on fa.id=fas.asset_id
					left join fin_storages fs on fs.id=fas.storage_id
				where
					(
						date('now')>=fag.start_date and
						(date('now')<=fag.end_date or fag.end_date is null)
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
				(select b.amount from balances b where b.asset_storage_id=fas.id order by b.date desc limit 1)*
				(select far.rate from fin_asset_rates far where far.asset_id=fa.id order by far.date desc limit 1)
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
	sort1 desc, priority desc;
CREATE VIEW "current_fin_asset_rates" as
select
	fa.id as pseudo_id,
	fat.name as asset_type,
	fa.code as asset,
	(select rate from fin_asset_rates far where far.asset_id=fa.id order by far.date desc limit 1) as rate,
	(select fa2.code from fin_assets fa2 where fa2.is_base limit 1) as base_asset
from
	fin_assets fa
	join fin_asset_types fat on fat.id=fa.type_id
where
	fa.is_active;
CREATE VIEW historical_monthly_balances as
with recursive dates(mo_start_date, date) as (
		values(
			date('now', 'start of month'),
			date('now', 'start of month', '+1 month', '-1 day')
		)
	union all
		select
			date(mo_start_date, '-1 month'),
			date(mo_start_date, '-1 day')
		from
			dates
		where
			mo_start_date > (select min(date) from balances)
		limit 10*12 -- use yearly view for periods over 10 years
),
constants as(
	select
		(select code from fin_assets fa2 where fa2.is_base limit 1) as base_asset
),

data_by_type as materialized( -- force materialize - 2x faster due to lead()
select
	d.date,
	fat.id as asset_type_id,
	(
		select
			sum(
				(select b.amount from balances b where b.asset_storage_id=fas.id and b.date<=d.date order by b.date desc limit 1)*
				(select far.rate from fin_asset_rates far where far.asset_id=fas.asset_id and far.date<=d.date order by far.date desc limit 1)
			)
		from
			fin_assets fa
			join fin_assets_storages fas on fas.asset_id=fa.id
		where
			fa.type_id=fat.id 
	) as base_balance,
	(
		select
			coalesce(sum(
				(select sum(ft.amount) from fin_transactions ft join fin_transaction_categories ftc on ftc.id=ft.category_id where ft.asset_storage_id=fas.id and ft.date>=d.mo_start_date and ft.date<=d.date and not ftc.is_rebalance and not ftc.is_passive and not ftc.is_initial_import)*
				(select far.rate from fin_asset_rates far where far.asset_id=fas.asset_id and far.date<=d.date order by far.date desc limit 1)
			),0)
		from
			fin_assets fa
			join fin_assets_storages fas on fas.asset_id=fa.id
		where
			fa.type_id=fat.id
	) as base_active_delta,
	(
		select
			coalesce(sum(
				(select sum(ft.amount) from fin_transactions ft join fin_transaction_categories ftc on ftc.id=ft.category_id where ft.asset_storage_id=fas.id and ft.date>=d.mo_start_date and ft.date<=d.date and ftc.is_initial_import)*
				(select far.rate from fin_asset_rates far where far.asset_id=fas.asset_id and far.date<=d.date order by far.date desc limit 1)
			),0)
		from
			fin_assets fa
			join fin_assets_storages fas on fas.asset_id=fa.id
		where
			fa.type_id=fat.id
	) as base_excluded_delta
from
	dates d
	cross join fin_asset_types fat
)

select
	t.date,
	round(sum(t.base_balance),2) as base_balance,
	round(sum(t.base_balance_delta),2) as base_balance_delta,
	round(sum(t.base_active_delta),2) as base_active_delta,
	round(sum(t.base_balance_delta)-sum(t.base_active_delta)-sum(t.base_excluded_delta),2) as base_passive_delta,
	(select base_asset from constants) as base_asset,
	group_concat(fat.name||'='||cast(t.base_balance as integer) || ' ' || (select base_asset from constants), ' ') as base_balance_by_type,
	group_concat(fat.name||'='||cast(t.base_balance_delta as integer) || ' ' || (select base_asset from constants), ' ') as base_balance_delta_by_type,
	group_concat(fat.name||'='||cast(t.base_active_delta as integer) || ' ' || (select base_asset from constants), ' ') as base_active_delta_by_type,
	group_concat(fat.name||'='||cast(t.base_balance_delta-t.base_active_delta-t.base_excluded_delta as integer) || ' ' || (select base_asset from constants), ' ') as base_passive_delta_by_type
from 
	(
		select
			t.*,
			t.base_balance-coalesce(
				lead(t.base_balance) over(partition by t.asset_type_id order by date desc),
				0
			) as base_balance_delta
		from
			data_by_type t
		where 
			t.base_balance is not null
	) t
	join fin_asset_types fat on fat.id=t.asset_type_id
group by
	1
order by
	t.date desc;
CREATE VIEW historical_monthly_txs_balances_mismatch as
with recursive dates(mo_start_date, date) as (
		values(
			date('now', 'start of month'),
			date('now', 'start of month', '+1 month', '-1 day')
		)
	union all
		select
			date(mo_start_date, '-1 month'),
			date(mo_start_date, '-1 day')
		from
			dates
		where
			mo_start_date > (select min(date) from balances) or
			mo_start_date > (select min(date) from fin_transactions)
		limit 2*12 -- 2 years
),
constants as (
	select
		(select min(mo_start_date) from dates) as start_date
)

select 
	t.mo_start_date as start_date,
	t.date as end_date,
	fs.name as storage,
	round(t.balance_delta - t.tx_delta,9) as amount_unaccounted,
	coalesce(fa.code,fa.name) as asset,
	t.tx_delta,
	t.balance_delta
from (
		select
			d.*,
			fas.asset_id as asset_id,
			fas.storage_id as storage_id,
			coalesce((select sum(amount) from fin_transactions ft where ft.asset_storage_id=fas.id and ft.date>=d.mo_start_date and ft.date<=d.date),0) as tx_delta,
			coalesce((
				select b.amount from balances b where b.asset_storage_id=fas.id and b.date<=d.date order by b.date desc limit 1
			),0) - coalesce((
				select coalesce(b.amount,0) from balances b where b.asset_storage_id=fas.id and b.date<d.mo_start_date order by b.date desc limit 1
			),0) as balance_delta
		from
			dates d
			cross join fin_assets_storages fas
	) t
	join fin_assets fa on fa.id=t.asset_id
	join fin_storages fs on fs.id=t.storage_id
where
	abs(t.tx_delta-t.balance_delta)>pow(10,-9)
order by
	t.date desc;
CREATE VIEW latest_fin_transactions as
select
	ft.id as pseudo_id,
	ft.date,
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
	ft.date desc,
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
	
	insert into balances(asset_storage_id, date, amount)
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
		date('now'),
		new.balance
	)
	on conflict(asset_storage_id, date) do update
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
	
	insert into balances(asset_storage_id, date, amount)
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
		date('now'),
		new.balance
	)
	on conflict(asset_storage_id, date) do update
	set 
		amount = new.balance;
		
end;
CREATE TRIGGER current_fin_asset_rates_insert
instead of insert on current_fin_asset_rates
begin
	insert into fin_asset_rates (asset_id, date, rate)
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
		date('now'),
		new.rate
	)
	on conflict(asset_id,date) do update 
	set rate=new.rate;
end;
CREATE TRIGGER current_fin_asset_rates_update
instead of update of rate on current_fin_asset_rates
begin
	insert into fin_asset_rates (asset_id, date, rate)
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
		date('now'),
		new.rate
	)
	on conflict(asset_id,date) do update 
	set rate=new.rate;
end;
CREATE TRIGGER fin_transaction_categories_insert insert on fin_transaction_categories
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
),
children(id) as (
	values(new.id)
	union
	select
		cat.id
	from 
		children c
		join fin_transaction_categories cat on cat.parent_id=c.id
	where
		cat.id!=new.id
)
select
	case
		when new.parent_id is not null and not exists(select 1 from fin_transaction_categories where id=new.parent_id)
			then raise(abort, 'parent does not exist')
		when new.parent_id is null and exists(select 1 from fin_transaction_categories where parent_id is null and id!=new.id)
			then raise(abort, 'root of the hierarchy already exists')
		when not exists(select 1 from parents where parent_id is null)
			then raise(abort, 'upper part of the hierarchy is circular')
		when (not new.is_passive and p.has_passive) or (not new.is_rebalance and p.has_rebalance) or (not new.is_initial_import and p.has_initial_import)
			then raise(abort, 'parent conditions not met')
		when (new.is_passive and c.has_not_passive) or (new.is_rebalance and c.has_not_rebalance) or (new.is_initial_import and c.has_not_initial_import)
			then raise(abort, 'child conditions not met')
	end
from
	(
		select
			coalesce(max(cat.is_passive),0) as has_passive,
			coalesce(max(cat.is_rebalance),0) as has_rebalance,
			coalesce(max(cat.is_initial_import),0) as has_initial_import
		from
			parents p
			join fin_transaction_categories cat on cat.id=p.parent_id
	) p,
	(
		select
			not coalesce(min(cat.is_passive),1) as has_not_passive,
			not coalesce(min(cat.is_rebalance),1) as has_not_rebalance,
			not coalesce(min(cat.is_initial_import),1) as has_not_initial_import
		from
			children c
			join fin_transaction_categories cat on cat.parent_id=c.id
	) c;
end;
CREATE TRIGGER fin_transaction_categories_update update of id,parent_id,is_passive,is_rebalance,is_initial_import on fin_transaction_categories
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
),
children(id) as (
	values(new.id)
	union
	select
		cat.id
	from 
		children c
		join fin_transaction_categories cat on cat.parent_id=c.id
	where
		cat.id!=new.id
)
select
	case
		when new.parent_id is not null and not exists(select 1 from fin_transaction_categories where id=new.parent_id)
			then raise(abort, 'parent does not exist')
		when new.parent_id is null and exists(select 1 from fin_transaction_categories where parent_id is null and id!=new.id)
			then raise(abort, 'root of the hierarchy already exists')
		when not exists(select 1 from parents where parent_id is null)
			then raise(abort, 'upper part of the hierarchy is circular')
		when (not new.is_passive and p.has_passive) or (not new.is_rebalance and p.has_rebalance) or (not new.is_initial_import and p.has_initial_import)
			then raise(abort, 'parent conditions not met')
		when (new.is_passive and c.has_not_passive) or (new.is_rebalance and c.has_not_rebalance) or (new.is_initial_import and c.has_not_initial_import)
			then raise(abort, 'child conditions not met')
	end
from
	(
		select
			coalesce(max(cat.is_passive),0) as has_passive,
			coalesce(max(cat.is_rebalance),0) as has_rebalance,
			coalesce(max(cat.is_initial_import),0) as has_initial_import
		from
			parents p
			join fin_transaction_categories cat on cat.id=p.parent_id
	) p,
	(
		select
			not coalesce(min(cat.is_passive),1) as has_not_passive,
			not coalesce(min(cat.is_rebalance),1) as has_not_rebalance,
			not coalesce(min(cat.is_initial_import),1) as has_not_initial_import
		from
			children c
			join fin_transaction_categories cat on cat.parent_id=c.id
	) c;
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
	
	insert into fin_transactions(date, asset_storage_id, amount, category_id, reason_fin_asset_storage_id, reason_phys_asset_ownership_id)
	values(
		coalesce(new.date, date('now')),
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
					coalesce(new.date, date('now'))>=pao.start_date and
					(coalesce(new.date, date('now'))<=pao.end_date or pao.end_date is null)
				)
		)
	);
	
	select
		case
			when coalesce(new.date, date('now'))!=date('now') and new.adjust_balance
			then raise(abort, 'adjust_balance works only with current date')
		end;
		
	insert into balances(date, asset_storage_id, amount)
	select
		date('now') as date,
		fas.id as asset_storage_id,
		coalesce((select b.amount from balances b where b.asset_storage_id=fas.id and b.date<=date('now') order by b.date desc limit 1),0)+new.amount as amount
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
	on conflict(date, asset_storage_id) do update
	set 
		amount = amount + new.amount;
end;
CREATE TRIGGER latest_fin_transactions_update
instead of update of date, asset_type, storage, amount, asset_code, category, reason_phys_asset, reason_fin_asset_type, reason_fin_asset_code, reason_fin_asset_storage on latest_fin_transactions
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
		date = new.date,
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
					coalesce(new.date, date('now'))>=pao.start_date and
					(coalesce(new.date, date('now'))<=pao.end_date or pao.end_date is null)
				)
		)
	where
		id=new.pseudo_id;
	
	select
		case
			when (coalesce(new.date, date('now'))!=date('now') or old.date!=date('now')) and new.adjust_balance
			then raise(abort, 'adjust_balance works only with current date')
		end;
	
	insert into balances(date, asset_storage_id, amount)
	select
		date('now') as date,
		fas.id as asset_storage_id,
		coalesce((select b.amount from balances b where b.asset_storage_id=fas.id and b.date<=date('now') order by b.date desc limit 1),0)+new.amount as amount
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
	on conflict(date, asset_storage_id) do update
	set 
		amount = amount + new.amount;
end;
