using Plots: push!
## imports

using Plots
using DataFrames
using CSV
using Pipe
using Statistics
using BenchmarkTools
using Test

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
scatter(process_num.(zip_df[:," popden "]), zip_df[:," Total Household Carbon Footprint (tCO2e/yr) "], legend=false)
title!("Household Emissions vs Population Density by Zip Code")
ylabel!("Total Household Carbon Footprint (tCO2e/yr)")
xlabel!("Population Density (persons/sq mi)")
savefig("./output/popden.png")

## retain desired rows/columns

# define lists of relevant column names for easy indexing into the data frame
all_cols = names(zip_df)
feature_cols = ["Population", "PersonsPerHousehold", "AverageHouseValue", "IncomePerHousehold", "Latitude", "Longitude", "Elevation", " popden ", "electricity (kWh)", "Nat. Gas (cu.ft.)", "FUELOIL (gallons)", " Vehicle miles traveled ", "HouseholdsPerZipCode"]
soln_col = " Total Household Carbon Footprint (tCO2e/yr) "

# limit dataframe to just feature and solution columns
zip_df = zip_df[:, [feature_cols; soln_col]]

## calculate correlations

# maps each feature column to a tuple of the column name and the correlation coefficient
correlations = map(col -> (col,cor(process_num.(zip_df[:,col]), zip_df[:,soln_col])), feature_cols)
