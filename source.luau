-- Copyright (c) 2025 META Interactive
-- Written by 9q7n

local Snowflake = {}

export type SnowflakeId = number
export type SnowflakeParsed = {
	timestamp: number,
	human_timestamp: string,
	worker_id: number,
	count: number,
	snowflake: SnowflakeId,
}

-- Constants for bit shifts and masks
local WORKER_ID_BITS: number = 5
local COUNT_BITS: number = 12
local MAX_COUNT: number = (2 ^ COUNT_BITS) - 1
local WORKER_ID_SHIFT: number = COUNT_BITS
local TIMESTAMP_SHIFT: number = WORKER_ID_SHIFT + WORKER_ID_BITS
local DEBUG_MODE: boolean = true

-- Variables
local EPOCH: number = 1420070400000 -- Default epoch is January 1st, 2015
local worker_id: number = 0
local count: number = 0
local last_timestamp: number = -1

-- Helper function to get the current timestamp in milliseconds
local function get_current_timestamp(): number
	return math.floor(tick() * 1000)
end

-- Helper function to wait for the next millisecond
local function wait_for_next_millisecond(timestamp: number): number
	while timestamp == last_timestamp do
		timestamp = get_current_timestamp()
	end

	return timestamp
end

function Snowflake.new(useString: boolean | nil): SnowflakeId
	if useString == nil then
		useString = false
	end

	local timestamp: number = get_current_timestamp()

	if timestamp < last_timestamp then
		error("Clock moved backwards. Refusing to generate id")
	end

	if timestamp == last_timestamp then
		count = (count + 1) % (MAX_COUNT + 1)
		if count == 0 then
			timestamp = wait_for_next_millisecond(timestamp)
		end
	else
		count = 0
	end

	last_timestamp = timestamp

	local id: SnowflakeId = ((timestamp - EPOCH) * (2 ^ TIMESTAMP_SHIFT)) + (worker_id * (2 ^ WORKER_ID_SHIFT)) + count

	return useString and tostring(id) or id
end

-- Function to parse a snowflake id
function Snowflake:parse(snowflake: SnowflakeId): SnowflakeParsed
	local timestamp: number = math.floor(snowflake / (2 ^ TIMESTAMP_SHIFT)) + EPOCH
	local worker_id: number = math.floor(snowflake / (2 ^ WORKER_ID_SHIFT)) % (2 ^ WORKER_ID_BITS)
	local count: number = snowflake % (2 ^ COUNT_BITS)

	if DEBUG_MODE then
		-- Convert timestamp from milliseconds to seconds for os.date
		local utc_time_in_seconds = math.floor(timestamp / 1000)
		local milliseconds = timestamp % 1000

		-- Function to determine if a given timestamp is in Daylight Saving Time
		local function is_dst(timestamp)
			local t = os.date("*t", timestamp)
			local start = os.time({ year = t.year, month = 3, day = 8, hour = 2, min = 0, sec = 0 })
			local end_ = os.time({ year = t.year, month = 11, day = 1, hour = 2, min = 0, sec = 0 })
			start = start + (8 - os.date("%w", start)) % 7 * 24 * 3600
			end_ = end_ + (7 - os.date("%w", end_)) % 7 * 24 * 3600
			return timestamp >= start and timestamp < end_
		end

		-- Determine if we should adjust for PDT or PST
		local is_in_dst = is_dst(utc_time_in_seconds)
		local pst_offset = is_in_dst and -7 * 3600 or -8 * 3600

		-- Adjust to PST/PDT
		local pst_time_in_seconds = utc_time_in_seconds + pst_offset

		local human_timestamp = os.date("%Y-%m-%d %H:%M:%S", pst_time_in_seconds) .. string.format(".%03d", milliseconds)

		print(human_timestamp)
	end

	return {
		timestamp = timestamp,
		human_timestamp = os.date("%Y-%m-%d %H:%M:%S", math.floor(timestamp / 1000)),
		worker_id = worker_id,
		count = count,
		snowflake = snowflake,
	}
end

-- Function to set the worker ID
function Snowflake:set_worker_id(new_worker_id: number)
	if new_worker_id < 0 or new_worker_id >= (2 ^ WORKER_ID_BITS) then
		error("Worker ID out of bounds")
	end

	worker_id = new_worker_id
end

-- Function to get the current worker ID
function Snowflake:get_worker_id(): number
	return worker_id
end

-- Function to set the epoch
function Snowflake:set_epoch(new_epoch: number)
	EPOCH = new_epoch
end

-- Function to get the current epoch
function Snowflake:get_epoch(): number
	return EPOCH
end

-- Function to validate a snowflake ID
function Snowflake:validate(snowflake: SnowflakeId): (boolean, string)
	if type(snowflake) ~= "number" or snowflake < 0 then
		return false, "Invalid snowflake format"
	end

	local timestamp: number = math.floor(snowflake / (2 ^ TIMESTAMP_SHIFT)) + EPOCH
	if timestamp < EPOCH then
		return false, "Timestamp out of range"
	end

	local worker_id: number = math.floor(snowflake / (2 ^ WORKER_ID_SHIFT)) % (2 ^ WORKER_ID_BITS)
	if worker_id < 0 or worker_id >= (2 ^ WORKER_ID_BITS) then
		return false, "Worker ID out of range"
	end

	local count: number = snowflake % (2 ^ COUNT_BITS)
	if count < 0 or count > MAX_COUNT then
		return false, "Count out of range"
	end

	return true, "Valid snowflake"
end

function Snowflake:isNewer(snowflake1: SnowflakeId, snowflake2: SnowflakeId): boolean
	return self:parse(snowflake1).timestamp > self:parse(snowflake2).timestamp
end

function Snowflake:compare(snowflake1: SnowflakeId, snowflake2: SnowflakeId): number
	local parsed1 = self:parse(snowflake1)
	local parsed2 = self:parse(snowflake2)

	if parsed1.timestamp > parsed2.timestamp then
		return 1 -- snowflake1 is newer
	elseif parsed1.timestamp < parsed2.timestamp then
		return -1 -- snowflake2 is newer
	else
		return 0 -- Both snowflakes are from the same timestamp, they are equal
	end
end

-- Function to calculate the age of a snowflake in days
function Snowflake:get_age_in_days(snowflake: SnowflakeId): number
	local parsed = self:parse(snowflake)
	local current_timestamp = get_current_timestamp()
	local age_in_milliseconds = current_timestamp - parsed.timestamp

	return age_in_milliseconds / (1000 * 60 * 60 * 24) -- Convert milliseconds to days
end

-- Function to calculate the age of a snowflake in hours
function Snowflake:get_age_in_hours(snowflake: SnowflakeId): number
	local parsed = self:parse(snowflake)
	local current_timestamp = get_current_timestamp()
	local age_in_milliseconds = current_timestamp - parsed.timestamp

	return age_in_milliseconds / (1000 * 60 * 60) -- Convert milliseconds to hours
end

-- Function to calculate the age of a snowflake in minutes
function Snowflake:get_age_in_minutes(snowflake: SnowflakeId): number
	local parsed = self:parse(snowflake)
	local current_timestamp = get_current_timestamp()
	local age_in_milliseconds = current_timestamp - parsed.timestamp

	return age_in_milliseconds / (1000 * 60) -- Convert milliseconds to minutes
end

-- Function to calculate the age of a snowflake in seconds
function Snowflake:get_age_in_seconds(snowflake: SnowflakeId): number
	local parsed = self:parse(snowflake)
	local current_timestamp = get_current_timestamp()
	local age_in_milliseconds = current_timestamp - parsed.timestamp

	return age_in_milliseconds / 1000 -- Convert milliseconds to seconds
end

-- Function to calculate the age of a snowflake in weeks
function Snowflake:get_age_in_weeks(snowflake: SnowflakeId): number
	local parsed = self:parse(snowflake)
	local current_timestamp = get_current_timestamp()
	local age_in_milliseconds = current_timestamp - parsed.timestamp

	return age_in_milliseconds / (1000 * 60 * 60 * 24 * 7) -- Convert milliseconds to weeks
end

-- Function to calculate the age of a snowflake in months (approximate)
function Snowflake:get_age_in_months(snowflake: SnowflakeId): number
	local parsed = self:parse(snowflake)
	local current_timestamp = get_current_timestamp()
	local age_in_milliseconds = current_timestamp - parsed.timestamp

	local average_milliseconds_per_month = 1000 * 60 * 60 * 24 * 30.44 -- Average month length (30.44 days)
	return age_in_milliseconds / average_milliseconds_per_month
end

-- Function to calculate the age of a snowflake in years (approximate)
function Snowflake:get_age_in_years(snowflake: SnowflakeId): number
	local parsed = self:parse(snowflake)
	local current_timestamp = get_current_timestamp()
	local age_in_milliseconds = current_timestamp - parsed.timestamp

	local average_milliseconds_per_year = 1000 * 60 * 60 * 24 * 365.25 -- Average year length (accounting for leap years)
	return age_in_milliseconds / average_milliseconds_per_year
end

-- Function to calculate the age of a snowflake in decades (approximate)
function Snowflake:get_age_in_decades(snowflake: SnowflakeId): number
	local parsed = self:parse(snowflake)
	local current_timestamp = get_current_timestamp()
	local age_in_milliseconds = current_timestamp - parsed.timestamp

	local average_milliseconds_per_decade = 1000 * 60 * 60 * 24 * 365.25 * 10 -- Average decade length
	return age_in_milliseconds / average_milliseconds_per_decade
end

return Snowflake
