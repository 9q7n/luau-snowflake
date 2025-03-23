# luau-snowflake

This module provides a Snowflake ID generator for Luau, designed for use in distributed systems to generate unique IDs based on timestamp, worker ID, and a sequence number.

## Features

- Generates unique Snowflake IDs
- Parses Snowflake IDs back into their components
- Configurable worker ID and epoch
- Validates Snowflake IDs

## Installation

To use this module, simply copy the `source.lua` file into your project.

## Usage

### Importing the Module

```luau
local Snowflake = require(path.to.Snowflake)
```

### Generating a Snowflake ID

```luau
local id = Snowflake.new()
print("Generated ID:", id)
```

### Parsing a Snowflake ID

```luau
local parsed = Snowflake:parse(id)
print("Parsed ID:", parsed)
```

### Setting and Getting Worker ID

```luau
Snowflake:set_worker_id(1)
local worker_id = Snowflake:get_worker_id()
print("Worker ID:", worker_id)
```

### Setting and Getting Epoch

```luau
Snowflake:set_epoch(1704067200000) -- January 1st, 2024
local epoch = Snowflake:get_epoch()
print("Epoch:", epoch)
```

### Validating a Snowflake ID

```luau
local is_valid, message = Snowflake:validate(id)
print("Is valid:", is_valid, "Message:", message)
```

### Comparing Snowflake IDs

You can compare two snowflake IDs to see which one is newer:

```luau
local result = Snowflake:compare(id1, id2)
if result == 1 then
    print("id1 is newer")
elseif result == -1 then
    print("id2 is newer")
else
    print("Both IDs are from the same timestamp")
end
```

Or using booleans:

```luau
local isNewer = Snowflake:is_newer(id1, id2)
if isNewer then
    print("id1 is newer")
else
    print("id2 is newer or both are from the same timestamp")
end
```

### Getting the Age of a Snowflake ID

You can get the age of a Snowflake ID in various units of time:

#### Days

```luau
local days = Snowflake:get_age_in_days(id)
print("Age in days:", days)
```

#### Hours

```luau
local hours = Snowflake:get_age_in_hours(id)
print("Age in hours:", hours)
```

#### Minutes

```luau
local minutes = Snowflake:get_age_in_minutes(id)
print("Age in minutes:", minutes)
```

#### Seconds

```luau
local seconds = Snowflake:get_age_in_seconds(id)
print("Age in seconds:", seconds)
```

#### Weeks

```luau
local weeks = Snowflake:get_age_in_weeks(id)
print("Age in weeks:", weeks)
```

#### Months (approximate)

```luau
local months = Snowflake:get_age_in_months(id)
print("Age in months:", months)
```

#### Years (approximate)

```luau
local years = Snowflake:get_age_in_years(id)
print("Age in years:", years)
```

#### Decades (approximate)

```luau
local decades = Snowflake:get_age_in_decades(id)
print("Age in decades:", decades)
```

## Types

The module uses the following custom types:

```luau
export type SnowflakeId = number
export type SnowflakeParsed = {
    timestamp: number,
    worker_id: number,
    count: number,
    snowflake: SnowflakeId
}
```

## License
This project is licensed under the MIT License.
