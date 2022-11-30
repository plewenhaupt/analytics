
# Load packages
using
DataFrames,
DataFramesMeta,
Dates,
Missings,
XLSX

# Check size of data file
file_path = "/Users/pederlewenhaupt/Misc/data.xlsx"
file_size = filesize(file_path)
kb = file_size/1000
mb = file_size/(1000^2)
filesize_df = DataFrame(bytes = file_size, kilobytes = round(kb, digits = 2), megabytes = round(mb, digits = 2))

# Load data
const original_data = @chain file_path XLSX.readtable(_, 1) DataFrame()

#######################################
# DATA INSPECTION AND TYPE FORMATTING #
#######################################
# Check size of tabular data
df_size = DataFrame(rows = nrow(original_data), columns = ncol(original_data))

# Ocular inspection of first 10 rows
first_df = first(original_data, 10)

# List column names
variable_names = @chain original_data names()

# Make a dataframe of question ids and questions
questions = [original_data[1,i] for i in 1:ncol(original_data)]
column_order_index = [1:ncol(original_data)...]
variable_dict = Dict(variable_names .=> questions)
variable_df = @chain DataFrame(variable_names = variable_names, questions = questions, column_order_index = column_order_index) sort()

# Remove the first row, containing the questions
const clean_data = original_data[Not([1]), :]

# Fix empty and missing
for col in variable_names
    clean_data[!, Symbol(col)] = passmissing((x -> x == "-" ? missing : x)).(clean_data[!, Symbol(col)])
end


# Create dictionary of unique values for each variable
unique_values_dict = Dict()
for col in variable_names
    unique_variable_values = @chain clean_data[!, Symbol(col)] unique()
    push!(unique_values_dict, col => unique_variable_values)
end
unique_values_dict = sort(unique_values_dict)

# Create array of data type for each column
variable_type_array = [
"string",
"string",
"string",
"string",
"string",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"int",
"int",
"int",
"int",
"string",
"int",
"string",
"string",
"int",
"int",
"string",
"int",
"int",
"string",
"string",
"int",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"int",
"int",
"int",
"datetime",
"int",
"int",
"int",
"string",
"int",
"int",
"int",
"int",
"boolean",
"string",
"string",
"int",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"string",
"date",
"datetime",
"int",
"int",
"string",
"int",
"string",
"date",
"date",
"float",
"date",
"string",
"int",
"int",
"int",
"string",
"float",
"float",
"int",
"string",
"string",
"string",
"int",
"int",
"string",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"int",
"string",
"string",
"string",
"string",
"string",
"int",
"int",
"int",
"int",
"string",
"int",
"string",
"float",
"int",
"int",
"int",
"string",
"int",
"string",
"int",
"int",
"datetime",
"string",
"string",
"int",
"int",
"string",
"string",
"int",
"int",
"int",
"date",
"datetime",
"string",
"string",
"string",
"int",
"int",
"int",
"int",
"string",
"string",
"date",
"string",
"string",
"string",
"int",
"int",
"string"
]

unique_types = @chain variable_type_array unique() sort()

# Create dataframe with variables and types
variable_df[!, "type"] = variable_type_array

# Assign the correct types to columns
# The general idea here is to treat each column individually, but if one column with a data type works, why not run a for loop and try the others as well?
# Boolean
#########
# Create array of boolean columns
boolean_columns = @chain variable_df @subset(:type .== "boolean")

# Assign boolean type to columns
for col in boolean_columns.variable_names
clean_data[!, Symbol(col)] = @chain clean_data[!, Symbol(col)] begin
                          (x -> x == 1.0 ? true : false).(_)
                      end
end
println("Boolean columns formatted")
# Date
#########
date_columns = @chain variable_df @subset(:type .== "date")

for col in date_columns.variable_names
    clean_data[!, Symbol(col)] = passmissing(x->Date(x, dateformat"yyyy-mm-dd")).(clean_data[!, Symbol(col)])
end
println("Date columns formatted")

# Datetime
#########
datetime_columns = @chain variable_df @subset(:type .== "datetime")

# No need to include these, since the columns already seem to be formatted
#=
for col in datetime_columns.variable_names
    clean_data[!, Symbol(col)] = passmissing(x->DateTime(x, dateformat"yyyy-mm-dd HH:MM:SS")).(clean_data[!, Symbol(col)])
end
println("Datetime columns formatted")
=#
# Float
#########
float_columns = @chain variable_df @subset(:type .== "float")

for col in float_columns.variable_names
    clean_data[!, Symbol(col)] = @chain clean_data[!, Symbol(col)] begin
                              passmissing(string).(_)
                              passmissing(parse).(Float64,_)
                          end
end
println("Float columns formatted")

# Int
#########
int_columns = @chain variable_df @subset(:type .== "int")

for col in int_columns.variable_names
    clean_data[!, Symbol(col)] = @chain clean_data[!, Symbol(col)] begin
                              passmissing(string).(_)
                              passmissing(parse).(Float64,_)
                              passmissing(x -> convert(Int64, x)).(_)
                          end
end
println("Int columns formatted")
# String
#########
string_columns = @chain variable_df @subset(:type .== "string")

for col in string_columns.variable_names
    clean_data[!, Symbol(col)] = @chain clean_data[!, Symbol(col)] passmissing(string).(_)
end
println("String columns formatted")

# Check the types
eltype_df = DataFrame(cols = names(clean_data), type = eltype.(eachcol(clean_data)))
