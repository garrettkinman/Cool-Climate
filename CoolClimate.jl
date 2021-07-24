## imports

using Plots
using DataFrames
using CSV
using Pipe
using Statistics
using BenchmarkTools
using Test

## load in data

zipcode_data = DataFrame(CSV.File("Zip-Code-Results.csv"))
city_data = DataFrame(CSV.File("City-Results.csv"))
county_data = DataFrame(CSV.File("County-Results.csv"))

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
scatter(process_num.(zipcode_data[:," popden "]), zipcode_data[:," Total Household Carbon Footprint (tCO2e/yr) "], legend=false)
title!("Household Emissions vs Population Density by Zip Code")
ylabel!("Total Household Carbon Footprint (tCO2e/yr)")
xlabel!("Population Density (persons/sq mi)")
savefig("./output/popden.png")

## calculate correlations

# define lists of relevant column names for easy indexing into the data frame
all_cols = names(zipcode_data)
feature_cols = ["Population", "PersonsPerHousehold", "AverageHouseValue", "IncomePerHousehold", "Latitude", "Longitude", "Elevation", " popden ", "electricity (kWh)", "Nat. Gas (cu.ft.)", "FUELOIL (gallons)", " Vehicle miles traveled ", "HouseholdsPerZipCode"]
soln_col = " Total Household Carbon Footprint (tCO2e/yr) "

# test to see the parsed data types of the columns
for col ∈ feature_cols
    println(typeof(zipcode_data[1,col]))
end

cor(process_num.(zipcode_data[:," popden "]), zipcode_data[:,soln_col])


correlations = zeros(length(feature_cols))
for col ∈ feature_cols
    # calculate correlation of each col to household emissions
    # because each col has different data types, process accordingly
    cor(process_num.(zipcode_data[:,col]), zipcode_data[:,soln_col])
end
correlations = map(col -> (col,cor(process_num.(zipcode_data[:,col]), zipcode_data[:,soln_col])), feature_cols)
