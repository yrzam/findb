# FinDB - personal financial data model & tools


## About

This repository contains the SQLite schema and scripts to handle financial data. It takes a generic approach to assets, transactions, balances and other things providing heavy automation capabilities, extensibility & deep analysis opportunities.


### Why SQLite but not spreadsheets?

* **Schema**. Spreadsheets are terrible. They're made for structured data although it is nearly impossible to structure data in them. A spreadsheet is literally a set of cells with their own rules, no decent data validation mechanisms, no entity relationship, and schema is stored entirely in the user's mind.

* **Interface.** You can easily render graphs on HTML pages. "DB Browser for SQLite" can be used to edit data. SQL is very convenient for analytical/bulk update purposes, for scripting such as automatic data import. Queries & DDL have great readability. And you may find other ways to interact with the database.

* **Performance, limitations, control.** This project can handle millions of rows, while it's simply impossible to store them in Excel. Indexes are a basic thing for a database. The user has wider control over query execution.

* **Portability.** SQLite runs everywhere, it's fast, lightweight, free, secure and does not need an internet connection.

### What to start with?
`fin_transactions` and `balances` are core tables that need regular updates. They will lead you to other important things. For convenience, see the views.


## Schema

Below you can find the short summary with usage notes for each table. Not all details are described. For the complete structure please see [DDL](./schema.sql).


### fin_assets (table)

A **Financial asset** is something you can track a balance of. It should be fungible and tradable.

```
id          (pk)
code        (no whitespaces, uppercase, unique per type text not null)
name        (text)
description (text)
type_id     (fk fin_asset_types not null)
is_base     (boolean as integer not null) - whether this is a main unit of measurement of your portfolio. Exactly one row must have this set to true
is_active   (boolean as integer not null)
```

> Example: US Dollar. 


### fin_asset_types (table)

A **type of financial asset** (also known as an asset class) describes the nature of the financial asset.

```
id   (pk)
name (text unique not null)
```

**The number of records should not exceed 8 due to presentation reasons.**

> Examples: fiat currency, equity, bond, etc.   


### fin_storages (table)

**Financial storage** represents a place where assets are kept.

```
id          (pk)
name        (text unique not null)
description (text)
is_active   (boolean as integer not null)
```

> Examples: savings account at a specific bank or broker, virtual debt account, bag at home, cryptocurrency wallet.


### fin_assets_storages (table)

Join table. Financial storage can hold many assets, and an asset can be held in many storages. These intersections must be unique.

```
id         (pk)
asset_id   (fk fin_assets not null)
storage_id (fk fin_storages not null)
priority   (integer unique) - used for sorting balances view and possibly other things 
allocation_group_id (fk fin_allocation_groups) - shows which allocation group does a specific asset stored in specific storage belong to 
```


### fin_asset_rates (table)

Stores historical exchange rates of financial assets.

```
id       (pk)
datetime (datetime as text not null)
asset_id (fk fin_assets not null)
rate     (real not null) - [asset value] / [base asset value]
```

Generally it is desired to know the exchange rate of an asset right before transaction or balance snapshot, although one may also use deep historical data for the analytical purposes.


### fin_transactions (table)

Stores historical transactions. Transaction is an action that leads to a balance change in exactly one place.

```
id               (pk)
datetime         (datetime as text not null)
description      (text)
asset_storage_id (fk fin_assets_storages not null) - points to storage and asset that took part in the transaction
amount           (not 0, real not null) - value, direction is determined by the sign
category_id      (fk fin_transaction_categories not null)
reason_fin_asset_storage_id (fk fin_asset_storages) - see below
reason_phys_asset_ownership_id (fk phys_asset_ownerships) - see below
```

`reason_*` should point to either a financial or a physical asset owned by person if two conditions are met:
1. Transaction occurred because of that ownership
2. Title of that ownership was not directly or indirectly affected by the current transaction.

You may group transactions into batches if it is impossible to log them all.


### fin_transaction_categories (table)

A **transaction category** describes the logical sense of the transaction.

Transaction categories must form a hierarchy with only one root. If a certain flag (starting with `is_`) is set to true on a category, it must be set to true on all of its child categories. The integrity is ensured via triggers that throw exceptions.

```
id                (pk)
name              (text unique not null)
is_passive        (boolean as integer not null) - see below
is_initial_import (boolean as integer not null) - whether the transaction is an upload of the existing assets for accounting
parent_id         (fk fin_transaction_categories) - reference to a category that is a superset of the current one 
min_view_depth    (integer not null) - in the flattened representation, category shall not appear on a level lower than N, N>=0. Parent category takes multiple levels instead
```

Income or expense is considered passive if three conditions are met:

1. It occurred because of some ownership
2. Title of that ownership was not directly or indirectly affected by this transaction
3.	* For gains, there are no significant non-monetary losses associated with the transaction reason.
	* For losses, there are no significant non-monetary gains associated with the transaction reason. 

> For example, paying tax for the property a person lives in is not a passive loss, although paying it for a property that they lend is a passive loss.

Any transaction of a category with `is_passive` must link to a `reason_*` asset, because conditions for setting a `reason_` on transaction are a subset of conditions for `is_passive` of a category. Although a transaction with `reason_*` may be classified as non-passive if it implied some non-monetary gains or losses. This distinction might be useful in evaluation of the overall impact of the asset.

> Examples of transaction categories: expense, salary transfer, rent payment, self transfer or exchange, dividends payout.


### balances (table)

Stores historical balances.

Balance is a verified snapshot of the amount of some asset stored at  an asset storage at a given time. Therefore, balance entry may appear anytime without prior transaction activity, and transaction does not create an obligation to update balance right after it happened. Balance is consistent with transactions as long as transaction delta before balance `datetime` equals the balance value: `[balance] = [sum amount of txs where tx datetime < balance datetime]`. Amount can be negative.

```
id       (pk)
datetime (datetime as text not null)
amount   (real not null)
asset_storage_id (fk fin_asset_storages not null)
```

Whenever possible, balance should be queried directly from this table instead of aggregating transactions.

One may argue that storing balances separately is a bad practice because it causes denormalization and data inconsistency. However, it is a deliberate choice to store conflicting data, as such data is loaded from external sources. Purpose of this project is to offer a viewpoint on multiple versions of data in order to resolve these conflicts.


### phys_assets (table)

Represents real-world assets, purchases and other non-fungible (non-interchangeable) things. The intended use case is to track large and important assets, especially ones that generate passive gains and losses.

```
id          (pk)
name        (text unique not null)
description (text)
```

> Examples: house, apartment rented for a year, commercial property, car


### phys_asset_ownerships (table)

Tracks whether physical asset is owned by a person at a particular moment. One asset may be owned at many time periods, or not be owned at all.

```
id             (pk)
asset_id       (fk phys_asset_id not null)
start_datetime (datetime as text not null) - since that moment an asset is owned
end_datetime - (datetime as text) - up to that moment (excl) an asset is owned. Owned indefinitely if null
```

Ownership periods for the same asset must not intersect.


### swaps (table)

Provides double-entry bookkeeping for the operations where both sides are tracked. Swap is an internal transfer of value that may happen between same or different assets, possibly of different nature. Swap changes the value allocation between financial accounts or physical items. 

```
id                        (pk)
credit_fin_transaction_id (fk fin_transactions)
credit_phys_ownership_id  (fk phys_asset_ownerships)
debit_fin_transaction_id  (fk fin_transactions)
debit_phys_ownership_id   (fk phys_asset_ownerships)
```

Therefore, possible operations are:
- fin asset -> fin asset (exchange or transfer)
- fin asset -> phys asset (buy)
- phys asset -> fin_asset (sell)
- phys asset -> phys asset (exchange)
- phys asset -> phys asset + fin asset (exchange with change)

> Examples: transfer between bank accounts, currency exchange, buying some item 


### balance_goals (table)

A **balance goal** is a plan to have a certain amount of financial assets on a balance for the specific purpose in the future, or keep it there constantly.

It is possible to have multiple goals per asset & storage - to complete all of them balance must be equal to or greater than sum of individual goals. Their progress is counted one by one according to the `priority`.

```
id               (pk)
name             (text not null)
asset_storage_id (fk fin_asset_storages not null)
amount           (real not null)
priority         (integer unique not null)
deadline         (datetime as text) - shows last desired date of completion
result_transaction_id (fk fin_transactions) - if saving resulted in a transaction, that transaction can be linked here. Such a goal will be considered complete
start_datetime   (datetime as text not null) 
end_datetime     (datetime as text) up to that moment goal is relevant, always relevant if set to null
```


### fin_allocation_groups (table)

This table sets a goal for the financial asset distribution.

Each asset & storage (`fin_assets_storages`) from your portfolio can reference a specific allocation group. Calculation should be performed based on `fin_asset_rates`.

```
id             (pk)
name           (text not null)
target_share   (real not null) - a desired fraction of all assets that the group should take, negative value means a negative target balance
start_datetime (datetime as text not null) - since that moment a rule is appled
end_datetime   (datetime as text) - up to that moment (excl) a rule is appled. Applied indefinitely if null
priority       (integer unique)
```

`target_share` may be any valid number as it shows proportion. Equal target shares indicate that values of the underlying assets should be the same. For a negative target share, there may exist a positive one with the same value that would compensate corresponding debt. Normalization should happen at a later stage.

> Examples: allocation group "CASH" should have a 5% target share in 2025 Q2


### fin_transaction_plans (table)

This is a core table of financial planning. It allows to specify expected transactions in a flexible way. 

Transaction plan describes a value delta tied to a specific `transaction category`. Parent category involves child categories, so any subtree of hierarchy may be covered. Plan may be also constrained with a specific `asset & storage`.

Plan may be single-run or recurrent. This is defined by presence of `recurrence_datetime_modifiers` which forms the date sequence, possibly ended by `end_datetime`. A `deviation_datetime_modifier` must be set to provide the allowed deviation of the factual datetime from the planned datetime. Plan execution is defined by plan/fact amounts and `criteria_operator` (less, more, etc.).

Balance may be nominated either in the base asset or in the asset of `asset & storage`. For recurrent plans, it is also possible to set the multiplier of amount per each iteration.

```
id                           (pk)
transaction_category_id      (fk fin_transaction_categories not null) - transaction category that this plan covers. Specify the root category if you want to cover all transactions.
criteria_operator            (text not null) - comparison operator used between desired amount and planned amount, one of [= > < <= >=]. For negative amounts, standard mathematical rules apply so that "more" operator leads to a greater balance
start_datetime               (datetime as text not null) - target transaction(s) datetime, for recurrent plan it defines datetime of the first iteration.
end_datetime                 (datetime as text) - stops the recurrent sequence.
recurrence_datetime_modifiers (semicolon separated datetime modifiers, up to 3, as text) - if set, it is used to make a possibly infinite sequence of datetime values, thus making the plan recurrent. Result must only increase. Last moment is defined by end_datetime if it is set. 
recurrence_amount_multiplier (real) - for recurrent plans, every subsequent amount will equal previous amount multiplied by this value, aka p=a*mult^N, where N starts with 0. Value of 1 used if not set.
deviation_datetime_modifier  (reversible positive datetime modifier as text not null) - allowed deviation of transactions' datetime from the plan datetime.  plan datetime += deviation defines a range in which tx delta is calculated.
asset_storage_id             (fk fin_assets_storages not null) asset storage which target transactions are going to be applied to.
local_amount                 (real) - amount in the currency of asset storage, allowed if base_amount is not set.
base_amount                  (real) - amount in the base currency, allowed if local_amount not set.
```


### current_balances (view)

Shows current financial balances. Inactive assets and storages are skipped.

If you edit `balance`, a supplied one will be saved with a date of the current day. Upon the insertion of a new row, a record in `fin_assets_storages` is created if needed and the balance is upserted.

> operations: select, update, insert

```
lookup tuple:
    asset_type (text lkp fin_asset_types.name not null)
	asset_code (text lkp fin_assets.code not null)
	storage    (text lkp fin_asset_storages.name)
value:
    balance    (real not null)
info:
    pseudo_id
	asset_name
	base_balance - balance converted to base_asset
	base_asset
```


### latest_fin_transactions (view)

Shows the latest transactions. All fields except for pseudo-id are editable.

For inserts, there is also one special column `adjust_balance` - it allows to auto-update `balances` with the amount of the current transaction. In such case, a new balance entry with datetime one second after transaction will be created or updated. Works only with current datetime. **Please be cautious: while this option is convenient, used wrongly it may mess up your balance. Verify balances.**

> operations: select, update, insert, delete

```
lookup:
    pseudo_id (pk)
values:
    amount (real not null)
	datetime (datetime as text not null)
	category (text lkp fin_transaction_categories not null)
	reason_phys_asset (text lkp phys_assets via phys_asset_ownerships at datetime)
value tuples:
	1.
		asset_type (text lkp fin_asset_types.name not null)
		asset_code (text lkp fin_assets.code not null)
		storage    (text lkp fin_asset_storages.name)
	2.
		reason_asset_type (text lkp fin_asset_types.name not null)
		reason_asset_code (text lkp fin_assets.code not null)
		reason_storage    (text lkp fin_asset_storages.name)
info:
	asset_name
special:
	adjust_balance (boolean as integer, insert only) - pseudo-column, if set to true current operation will be auto-reflected in balances. Works only if transaction has datetime of the current moment
```


### historical_txs_balances_mismatch (view)

Allows to keep balances consistent with transactions for the analytical purposes.

This view contains a row only if there is a mismatch between transaction delta and balance delta during the last 2 years. It is advised to keep this view empty via adding missing transactions or adjusting balances.

> operations: select

```
info:
	start_datetime
	end_datetime
	storage
	amount_unaccounted - difference between balance and transaction delta
	tx_delta
	balance_delta
```


### current_fin_asset_rates (view)

Shows current exchange rates. Inactive assets are skipped. If you modify something, a new rate will be saved with a `datetime` of the current moment.

> operations: select, update, insert

```
lookup tuple:
    asset_type (text lkp fin_asset_types.name not null)
    asset      (text lkp fin_assets.code not null)
value:
    rate       (real not null)
info:
    pseudo_id
	base_asset
```


### historical_monthly_balances

Shows monthly changes of balances, both total and detailed by the asset type. It also summarizes transaction data in order to present the following categories:

* balance delta - change of the balance since the previous month
* active delta - change caused by active profits and losses (transactions)
* passive delta - changes caused by passive profits and losses (transactions) and by fluctuations of the exchange rates
* unaccounted delta - changes:
	* not reflected in transactions
	* caused by initial import of assets
	* caused by the swap of one financial asset to another. In that case, amount is calculated based on the credit transaction amount for both source and destination and then converted to the base asset. Thus, total amount always equals zero, although for cross-type conversions it will equal the same amount with the opposite sign. Spread losses are counted as passive losses.

> operations: select

```
info:
	start_datetime
	end_datetime
	base_balance - total balance
	base_balance_delta - total balance change since prev month
	base_active_delta
	base_passive_delta
	base_unaccounted_delta
	base_asset
	base_balance_by_type
	base_balance_delta_by_type
	base_active_delta_by_type
	base_passive_delta_by_type
	base_unaccounted_delta_by_type
```

For the most accurate results, `balances` and `fin_asset_rates` should be up-to-date right before the month ends. Note that transaction datetimes must be less then datetime of the balance snapshot. For exchange transactions, `fin_asset_rates` should be up-to-date for the asset which was sent at a datetime of sending transaction (otherwise the most recent rate at that time will be used). 


### current_balance_goals (view)

View that shows statuses of all goals (amount left, whether goal is accomplished, etc.). 

Goals that result in financial transactions are hidden. Goal is considered accomplished if there are enough corresponding assets on the balance. It is reversible, thus needs your attention. Accomplished goals are listed at the bottom of the view.

Goal is considered irrelevant and thus not shown if it either resulted in a transaction or the current moment is outside of the goal's datetime range. 

> operations: select

```
info:
	is_accomplished
	goal
	storage
	amount_total
	amount_left
	deadline
```


### current_fin_allocation (view)

Shows current asset allocation calculated based on your balance and exchange rates. Both current and target shares are displayed.

> operations: select

```
info:
	group
	base_balance
	base_asset
	current_share - calculated as balance / sum(abs(balance))
	target_share
```

Sum of `current_share` percentages without sign is always 100. However, negative balance leads to a negative share. Thus the real sum may vary from `-100` to `100`, where `100` means that all accounted balances are positive, `-100` means they are negative, `0` means that sum of negative balances equals sum of positive balances multiplied by `-1`.


## Schema conventions

### Structure
* Schema shall be described in pure DDL. No initial tuples are allowed.
* Each table has an `id` column as a primary key, stated as `INTEGER AUTOINCREMENT`, all foreign keys are also `INTEGER`s.
* Use strict types, but do not enable strict mode. Boolean is `INTEGER` 1 or 0, datetime is `TEXT`, numeric is `REAL` (unfortunately).
* Enforce unique in constraints, not indexes.
* Editable views have a `pseudo_id` column with unique non-null values so that client software can identify which row is being edited.

### Performance
* Expect gigabytes of data, do tricks such as force materializing.
* Do not use a view as a part of another view.
* The primary query is `SELECT`, so it makes sense to create many indexes.
* Always index foreign keys, remove indexes that are part of other covering indexes.
* Rely on internal indexes produced by primary keys and `UNIQUE` constraint

### Naming
* Snake case for identifiers, no prefixes except for indexes.
* Index name must be `i_[table_name]_[column names joined by "_"]`.
* The last noun in the table name is pluralized.
* Many-to-many (join) tables are named with a combination of tables they join. Although if referred tables have the same name prefix, it shall be used once. The table that usually has more records comes first.
> fin_assets + fin_storages => fin_assets_storages 
* Foreign key column names must end with `_id` and should point to the primary key. Their names must meet the table context and usually do not need extra database-wide prefixing.
* Names of the columns that store boolean must start with `is_`

### Common names
* `code` - string identifier that is required, unique in some way per table case-insensitively and contains no spaces. `code` is a static thing used to identify rows externally upon data edit.
* `name` - identifier for the display purposes, that can be edited anytime
* `priority` - unique `INTEGER` value for sorting and other purposes
* `is_active` - used to hide non-needed entries from the current representation, keeping them as historical data  
