-- package-id|x-plane-zibo-vnav-descent-tables
-- package-version|v0.2.0
-- aircraft-family|zibo_upstream
-- BEGIN UPSTREAM VARIANT TEST: Zibo 737-800X VNAV descent tables
-- Zibo-only installer payload.
-- Goal: source-backed clean descent geometry for the Zibo 737-800X using the same data package as the C++ port.
-- Direct data: Documentation/levelup_vnav_descent_model/direct_descent_distance_tables.csv
-- Derived data: Documentation/levelup_vnav_descent_model/known_model_data.csv
-- Missing variant-specific data stays explicit: decel and non-clean flap descent are inherited from original Lua.

B738_variant_test_zibo_800_variant = -1000

-- Zibo 737-800X / CFM56-7B26
raw_table('B738_variant_test_800_direct_alt')
B738_variant_test_800_direct_alt = { 0, 1500, 5000, 10000, 15000, 17000, 19000, 21000, 23000, 25000, 27000, 29000, 31000, 33000, 35000, 37000, 39000, 41000 }
raw_table('B738_variant_test_800_direct_weight')
B738_variant_test_800_direct_weight = { 40000, 50000, 60000, 70000 }
raw_table('B738_variant_test_800_direct_078_280_250')
B738_variant_test_800_direct_078_280_250 = {
	[40000] = { 0, 9, 18, 30, 43, 48, 52, 57, 61, 66, 70, 75, 80, 84, 88, 92, 96, 101 },
	[50000] = { 0, 9, 19, 34, 49, 55, 60, 65, 71, 76, 82, 87, 93, 98, 102, 107, 112, 118 },
	[60000] = { 0, 9, 20, 36, 54, 60, 66, 72, 78, 84, 90, 96, 103, 109, 113, 119, 124, 130 },
	[70000] = { 0, 9, 21, 38, 57, 63, 70, 76, 83, 90, 96, 103, 110, 116, 121, 127, 132, 137 },
}
raw_table('B738_variant_test_800_derived_076_280_alt')
B738_variant_test_800_derived_076_280_alt = { 0, 10000, 20000, 30000, 40000 }
raw_table('B738_variant_test_800_derived_076_280_weight')
B738_variant_test_800_derived_076_280_weight = { 40000, 50000, 60000, 70000, 80000 }
raw_table('B738_variant_test_800_derived_076_280_dist_per_1000')
B738_variant_test_800_derived_076_280_dist_per_1000 = {
	[40000] = { 2.029, 2.172, 2.205, 2.408, 2.691 },
	[50000] = { 2.456, 2.586, 2.664, 2.871, 2.906 },
	[60000] = { 2.745, 3.017, 2.906, 3.246, 2.906 },
	[70000] = { 3.111, 3.194, 3.197, 3.555, 2.691 },
	[80000] = { 3.333, 3.394, 3.365, 3.555, 2.422 },
}


B738_variant_test_models = {
	[B738_variant_test_zibo_800_variant] = {
		label = 'Zibo 737-800X / CFM56-7B26',
		direct_alt = B738_variant_test_800_direct_alt,
		direct_weight = B738_variant_test_800_direct_weight,
		direct_078_280_250 = B738_variant_test_800_direct_078_280_250,
		derived_alt = B738_variant_test_800_derived_076_280_alt,
		derived_weight = B738_variant_test_800_derived_076_280_weight,
		derived_076_280 = B738_variant_test_800_derived_076_280_dist_per_1000,
	},
}

function B738_variant_test_number(value)
	if type(value) ~= 'number' or value ~= value or value == math.huge or value == -math.huge then
		return nil
	end
	return value
end

function B738_variant_test_active_variant()
	local zibo_variant = B738_variant_test_number(B738DR_73x)
	if zibo_variant == 0 then
		return B738_variant_test_zibo_800_variant
	end

	return nil
end

function B738_variant_test_clamp(value, lo, hi)
	value = B738_variant_test_number(value)
	lo = B738_variant_test_number(lo)
	hi = B738_variant_test_number(hi)
	if value == nil or lo == nil or hi == nil then
		return nil
	end
	if value < lo then
		return lo
	elseif value > hi then
		return hi
	end
	return value
end

function B738_variant_test_round(value)
	value = B738_variant_test_number(value)
	if value == nil then
		return nil
	end
	return math.floor(value + 0.5)
end

function B738_variant_test_in_range(value, lo, hi)
	value = B738_variant_test_number(value)
	lo = B738_variant_test_number(lo)
	hi = B738_variant_test_number(hi)
	if value == nil or lo == nil or hi == nil then
		return false
	end
	return value >= lo and value <= hi
end

function B738_variant_test_low_restriction_supported(low_restriction)
	return low_restriction == 0 or B738_variant_test_in_range(low_restriction, 230, 260)
end

function B738_variant_test_schedule_model()
	local variant_id = B738_variant_test_active_variant()
	if variant_id == nil then
		return nil, nil
	end

	local descent_mach = B738_variant_test_number(B738DR_fmc_descent_speed_mach)
	local descent_kias_value = B738_variant_test_number(B738DR_fmc_descent_speed)
	local low_restriction_value = B738_variant_test_number(B738DR_fmc_descent_r_speed1)
	if descent_mach == nil or descent_kias_value == nil or low_restriction_value == nil then
		return nil, nil
	end

	local cruise_mach = B738_variant_test_round(descent_mach * 1000)
	local descent_kias = B738_variant_test_round(descent_kias_value)
	local low_restriction = B738_variant_test_round(low_restriction_value)

	if B738_variant_test_in_range(cruise_mach, 770, 795) and
		B738_variant_test_in_range(descent_kias, 270, 310) and
		B738_variant_test_low_restriction_supported(low_restriction) then
		return variant_id, 'direct_078_280_250'
	end

	if B738_variant_test_in_range(cruise_mach, 650, 749) and
		B738_variant_test_in_range(descent_kias, 230, 310) and
		B738_variant_test_low_restriction_supported(low_restriction) then
		return variant_id, 'direct_078_280_250'
	end

	if B738_variant_test_in_range(cruise_mach, 750, 770) and
		B738_variant_test_in_range(descent_kias, 265, 310) then
		return variant_id, 'derived_076_280'
	end

	return nil, nil
end

function B738_variant_test_model(variant_id)
	if variant_id == nil then
		return nil
	end
	return B738_variant_test_models[variant_id]
end

function B738_variant_test_direct_table(model, model_id)
	if model_id == 'direct_078_280_250' then
		return model.direct_078_280_250
	end
	return nil
end

function B738_variant_test_interp_axis(axis, row, value)
	if type(axis) ~= 'table' or type(row) ~= 'table' or #axis < 1 or #row < 1 then
		return nil
	end
	local clamped_value = B738_variant_test_clamp(value, axis[1], axis[#axis])
	if clamped_value == nil then
		return nil
	end
	for ii = 2, #axis do
		if clamped_value <= axis[ii] then
			return B738_rescale(axis[ii - 1], row[ii - 1], axis[ii], row[ii], clamped_value)
		end
	end
	return row[#row]
end

function B738_variant_test_interp_weighted_curve(table_ref, axis, weight_axis, value, weight_kg)
	if type(table_ref) ~= 'table' or type(axis) ~= 'table' or type(weight_axis) ~= 'table' or #weight_axis < 1 then
		return nil
	end
	local weight = B738_variant_test_clamp(weight_kg, weight_axis[1], weight_axis[#weight_axis])
	if weight == nil then
		return nil
	end
	for ii = 2, #weight_axis do
		if weight <= weight_axis[ii] then
			local lo_weight = weight_axis[ii - 1]
			local hi_weight = weight_axis[ii]
			local lo_value = B738_variant_test_interp_axis(axis, table_ref[lo_weight], value)
			local hi_value = B738_variant_test_interp_axis(axis, table_ref[hi_weight], value)
			if lo_value == nil or hi_value == nil then
				return nil
			end
			return B738_rescale(lo_weight, lo_value, hi_weight, hi_value, weight)
		end
	end
	return B738_variant_test_interp_axis(axis, table_ref[weight_axis[#weight_axis]], value)
end

function B738_variant_test_direct_segment(model, model_id, low_alt, high_alt)
	local table_ref = B738_variant_test_direct_table(model, model_id)
	if table_ref == nil or type(model.direct_alt) ~= 'table' or type(model.direct_weight) ~= 'table' then
		return nil
	end
	high_alt = B738_variant_test_number(high_alt)
	low_alt = B738_variant_test_number(low_alt)
	if high_alt == nil or low_alt == nil or high_alt > model.direct_alt[#model.direct_alt] then
		return nil
	end

	local total_weight = B738_variant_test_number(simDR_total_weight)
	if total_weight == nil then
		return nil
	end
	local weight = total_weight
	local high_dist = B738_variant_test_interp_weighted_curve(table_ref, model.direct_alt, model.direct_weight, high_alt, weight)
	local low_dist = B738_variant_test_interp_weighted_curve(table_ref, model.direct_alt, model.direct_weight, low_alt, weight)
	if high_dist == nil or low_dist == nil then
		return nil
	end
	local segment = high_dist - low_dist
	if segment < 0 then
		return nil
	end
	return segment
end

function B738_variant_test_derived_value_per_1000(model, altitude_ft, weight_kg)
	if type(model) ~= 'table' or type(model.derived_076_280) ~= 'table' or type(model.derived_alt) ~= 'table' or type(model.derived_weight) ~= 'table' then
		return nil
	end
	return B738_variant_test_interp_weighted_curve(model.derived_076_280, model.derived_alt, model.derived_weight, altitude_ft, weight_kg)
end

function B738_variant_test_next_derived_alt(model, current_alt, target_alt)
	local next_alt = target_alt
	for ii = 2, #model.derived_alt do
		local axis_alt = model.derived_alt[ii]
		if axis_alt > current_alt then
			next_alt = math.min(axis_alt, target_alt)
			break
		end
	end
	if next_alt <= current_alt then
		next_alt = target_alt
	end
	return next_alt
end

function B738_variant_test_derived_cumulative(model, altitude_ft, weight_kg)
	if type(model.derived_alt) ~= 'table' then
		return nil
	end
	local max_alt = model.derived_alt[#model.derived_alt]
	local target_alt = B738_variant_test_clamp(altitude_ft, 0, max_alt)
	if target_alt == nil then
		return nil
	end
	local current_alt = 0
	local distance = 0
	while current_alt < target_alt do
		local next_alt = B738_variant_test_next_derived_alt(model, current_alt, target_alt)
		if next_alt <= current_alt then
			break
		end
		local current_rate = B738_variant_test_derived_value_per_1000(model, current_alt, weight_kg)
		local next_rate = B738_variant_test_derived_value_per_1000(model, next_alt, weight_kg)
		if current_rate == nil or next_rate == nil then
			return nil
		end
		distance = distance + (((current_rate + next_rate) * 0.5) * ((next_alt - current_alt) / 1000))
		current_alt = next_alt
	end
	return distance
end

function B738_variant_test_derived_segment(model, low_alt, high_alt)
	if type(model.derived_alt) ~= 'table' then
		return nil
	end
	high_alt = B738_variant_test_number(high_alt)
	low_alt = B738_variant_test_number(low_alt)
	if high_alt == nil or low_alt == nil or high_alt > model.derived_alt[#model.derived_alt] then
		return nil
	end

	local total_weight = B738_variant_test_number(simDR_total_weight)
	if total_weight == nil then
		return nil
	end
	local weight = total_weight
	local high_dist = B738_variant_test_derived_cumulative(model, high_alt, weight)
	local low_dist = B738_variant_test_derived_cumulative(model, low_alt, weight)
	if high_dist == nil or low_dist == nil then
		return nil
	end
	local segment = high_dist - low_dist
	if segment < 0 then
		return nil
	end
	return segment
end

function B738_variant_test_can_use_kias_segment(model_id, speed_kias)
	local rounded_speed_kias = B738_variant_test_round(speed_kias)
	if model_id == 'derived_076_280' then
		return B738_variant_test_in_range(rounded_speed_kias, 265, 310)
	end

	if model_id == 'direct_078_280_250' then
		return B738_variant_test_in_range(rounded_speed_kias, 230, 310)
	end

	return false
end

function B738_variant_test_can_use_mach_segment(model_id, mach)
	mach = B738_variant_test_number(mach)
	if mach == nil then
		return false
	end
	local mach_x1000 = B738_variant_test_round(mach * 1000)
	if model_id == 'derived_076_280' then
		return B738_variant_test_in_range(mach_x1000, 750, 770)
	end

	if model_id == 'direct_078_280_250' then
		return B738_variant_test_in_range(mach_x1000, 770, 795)
	end

	return false
end

function B738_variant_test_wind_correct(segment, x_spd_wnd_alt, high_alt)
	segment = B738_variant_test_number(segment)
	x_spd_wnd_alt = B738_variant_test_number(x_spd_wnd_alt)
	high_alt = B738_variant_test_number(high_alt)
	if segment == nil or x_spd_wnd_alt == nil or high_alt == nil then
		return nil
	end
	return segment + (segment * x_spd_wnd_alt * B738_rescale(10000, 0.0032, 34000, 0.0022, high_alt))
end

function B738_variant_test_alt_band(x_idx_alt)
	x_idx_alt = B738_variant_test_round(x_idx_alt)
	if x_idx_alt == nil or type(vnav_des_alt) ~= 'table' then
		return nil, nil
	end
	local high_alt = vnav_des_alt[x_idx_alt]
	if high_alt == nil then
		return nil, nil
	end

	local low_alt = 0
	if x_idx_alt > 1 and vnav_des_alt[x_idx_alt - 1] ~= nil then
		low_alt = vnav_des_alt[x_idx_alt - 1]
	end

	if low_alt < 0 or high_alt <= low_alt then
		return nil, nil
	end
	return low_alt, high_alt
end

function B738_variant_test_take_alt_dist(x_idx_alt, x_spd_alt, x_spd_wnd_alt, x_flap)
	x_flap = B738_variant_test_number(x_flap)
	if x_flap ~= 0 then
		return nil
	end

	local variant_id, model_id = B738_variant_test_schedule_model()
	if variant_id == nil then
		return nil
	end

	local model = B738_variant_test_model(variant_id)
	if model == nil then
		return nil
	end

	local low_alt, high_alt = B738_variant_test_alt_band(x_idx_alt)
	if high_alt == nil then
		return nil
	end

	local speed_kias = B738_variant_test_clamp(x_spd_alt, 0, 400)
	if speed_kias == nil then
		return nil
	end
	if not B738_variant_test_can_use_kias_segment(model_id, speed_kias) then
		return nil
	end

	local segment = nil
	if model_id == 'derived_076_280' then
		segment = B738_variant_test_derived_segment(model, low_alt, high_alt)
	elseif model_id == 'direct_078_280_250' then
		segment = B738_variant_test_direct_segment(model, model_id, low_alt, high_alt)
	end
	if segment == nil then
		return nil
	end
	return B738_variant_test_wind_correct(segment, x_spd_wnd_alt, high_alt)
end

function B738_variant_test_take_alt_dist_mach(x_idx_alt, x_spd_alt, x_spd_wnd_alt)
	local variant_id, model_id = B738_variant_test_schedule_model()
	if variant_id == nil then
		return nil
	end

	local model = B738_variant_test_model(variant_id)
	if model == nil then
		return nil
	end

	if not B738_variant_test_can_use_mach_segment(model_id, x_spd_alt) then
		return nil
	end

	local low_alt, high_alt = B738_variant_test_alt_band(x_idx_alt)
	if high_alt == nil then
		return nil
	end

	local segment = nil
	if model_id == 'derived_076_280' then
		segment = B738_variant_test_derived_segment(model, low_alt, high_alt)
	elseif model_id == 'direct_078_280_250' then
		segment = B738_variant_test_direct_segment(model, model_id, low_alt, high_alt)
	end
	if segment == nil then
		return nil
	end
	return B738_variant_test_wind_correct(segment, x_spd_wnd_alt, high_alt)
end
-- END UPSTREAM VARIANT TEST: Zibo 737-800X VNAV descent tables
