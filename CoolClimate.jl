## imports

using Plots
using DataFrames
using CSV
using Pipe
using Statistics
using BenchmarkTools
using Test
using Printf

## load in data

# dataframe containing zipcode data
zip_df = DataFrame(CSV.File("Zip-Code-Results.csv"))

# TODO later
# city_data = DataFrame(CSV.File("City-Results.csv"))
# county_data = DataFrame(CSV.File("County-Results.csv"))

## declare helper functions

# simple function to process the messy strings into ints
# uses multiple dispatch to simplify calling conditions on varying types
# try/catch block is to convert invalid numbers (as seen in the data) to "missing"
# which helps filter out that data later
process_num(x::AbstractString) = @pipe x |> strip |> replace(_, ","=>"") |> try parse(Float64, _) catch; missing end
process_num(x::Union{Integer,AbstractFloat}) = Float64(x)

@testset "process_num" begin
    # valid, simple numbers
    @test process_num(6) == 6.0
    @test process_num(6.0) == 6.0
    @test process_num("6") == 6.0
    @test process_num("6.0") == 6.0

    # valid numbers needing processing
    @test process_num(" 6 ") == 6.0
    @test process_num(" 6,000 ") == 6000.0
    @test process_num(" 6000.0 ") == 6000.0
    @test process_num(" 6,000.0 ") == 6000.0
    @test process_num(" -6000 ") == -6000.0
    @test process_num(" -6,000.0") == -6000.0

    # invalid numbers to be handled
    @test ismissing(process_num(" - "))
    @test ismissing(process_num(""))
    @test ismissing(process_num(" "))
end

## explore simple data

# plot!
scatter(process_num.(zip_df[:,"Population Density (persons/sq mi)"]), zip_df[:,"Total Household Carbon Footprint (tCO2e/yr)"], legend=false)
title!("Household Emissions vs Population Density by Zip Code")
ylabel!("Total Household Carbon Footprint (tCO2e/yr)")
xlabel!("Population Density (persons/sq mi)")
savefig("./output/popden-household.png")

## retain desired rows/columns

# define lists of relevant column names for easy indexing into the data frame
all_cols = names(zip_df)
feature_cols = ["Population", "Persons Per Household", "Average House Value (USD)", "Income Per Household (USD)", "Latitude", "Longitude", "Elevation (ft)", "Population Density (persons/sq mi)", "Electricity (kWh)", "Natural Gas (cu ft)", "Fuel Oil (gal)", "Vehicle Miles Traveled", "Households Per Zip Code"]
soln_col = "Total Household Carbon Footprint (tCO2e/yr)"

# limit dataframe to just feature and solution columns
zip_df = zip_df[:, [feature_cols; soln_col]]

## calculate correlations

# maps each feature column to a tuple of the column name and the correlation coefficient
correlations = map(col -> (col,cor(process_num.(zip_df[:,col]), zip_df[:,soln_col])), feature_cols)

## calculate correlations per capita

# perhaps unsurprisingly, we find that persons per household correlates fairly strongly with household emissions
# so let's construct a more useful metric: emissions per capita
zip_df."Emissions Per Capita (tCO2e/yr)" = zip_df[:,soln_col] ./ zip_df[:, feature_cols[2]]
soln_col = "Emissions Per Capita (tCO2e/yr)"
correlations = map(col -> (col,cor(abs.(process_num.(zip_df[:,col])), zip_df[:,soln_col])), feature_cols)

## declare regex helper function

# match enclosed parentheses at end of feature columns
UNITS_REGEX = r"\([a-zA-Z\d/ ]*\)$"

# strip enclosing parentheses and all spaces
# for clean and elegant filenames
strip_units(str::AbstractString) = replace(str, UNITS_REGEX=>"")
process_name(str::AbstractString) = @pipe str |> strip_units |> replace(_, " "=>"")

@test process_name.(feature_cols) == ["Population","PersonsPerHousehold","AverageHouseValue","IncomePerHousehold","Latitude","Longitude","Elevation","PopulationDensity","Electricity","NaturalGas","FuelOil","VehicleMilesTraveled","HouseholdsPerZipCode"]

## explore simple data per capita

# plot!
for feature ∈  feature_cols
    plot = scatter(process_num.(zip_df[:,feature]), zip_df[:, soln_col], legend=false)
    title!(plot, @sprintf("%s vs %s", strip(strip_units(soln_col)), strip(strip_units(feature))))
    ylabel!(plot, soln_col)
    xlabel!(plot, feature)
    savefig(plot, @sprintf("./output/%s.png", process_name(feature)))
end

## calculate correlations for different functions

correlations_sq = map(col -> (col,cor(process_num.(zip_df[:,col]).^2, zip_df[:,soln_col])), feature_cols)
correlations_sqrt = map(col -> (col,cor(.√(abs.(process_num.(zip_df[:,col]))), zip_df[:,soln_col])), feature_cols)
correlations_exp = map(col -> (col,cor(exp.(abs.(process_num.(zip_df[:,col]))), zip_df[:,soln_col])), feature_cols)
correlations_ln = map(col -> (col,cor(log.(abs.(process_num.(zip_df[:,col]))), zip_df[:,soln_col])), feature_cols)

features = DataFrame()