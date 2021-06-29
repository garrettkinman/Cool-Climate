## imports

using Plots
using DataFrames
using CSV
using Flux
using Pipe

## load in data

zipcode_data = DataFrame(CSV.File("Zip-Code-Results.csv"))
city_data = DataFrame(CSV.File("City-Results.csv"))
county_data = DataFrame(CSV.File("County-Results.csv"))

## explore simple data

process_int(x::AbstractString) = @pipe x |> strip |> replace(_, ","=>"") |> parse(Int, _)
scatter(process_int.(zipcode_data[:," popden "]), zipcode_data[:," Total Household Carbon Footprint (tCO2e/yr) "], legend=false)
title!("Household Emissions vs Population Density by Zip Code")
ylabel!("Total Household Carbon Footprint (tCO2e/yr)")
xlabel!("Population Density (persons/sq mi)")

