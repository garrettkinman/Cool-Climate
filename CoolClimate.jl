## imports

using Plots
using DataFrames
using CSV
using Flux

## load in data

zipcode_data = DataFrame(CSV.File("Zip-Code-Results.csv"))
city_data = DataFrame(CSV.File("City-Results.csv"))
county_data = DataFrame(CSV.File("County-Results.csv"))

## explore simple data
