#=
Created on Monday 18th of January 2021
Last update: Tuesday 19th of January 2021

@author: Bram De Jaegher
bram.de.jaegher@gmail.com
=#

#=______________________
|                       |
|         Day 1         |
|_______________________|
=#

#= Notebook 1: basics =#
### Clipping
function clip(x)
  if x ≤ 0 && return 0.
  elseif x ≥ 1 && return 1.
  return x
  end
end

### Stirling
stirling(n) = sqrt(2*π*n)*(n/exp(1))^n

### Time is relative
function since_epoch(t)
  now = t
  seconds = now % 60 # 60 seconds in a minute
  now -= seconds
  # to minutes
  now = div(now, 60) 
  minutes = now % 60 # 60 minutes in an hour
  now -= minutes
  # to hours
  now = div(now, 60)
  hours = now % 24 # 24 hours in a day
  now -= hours
  # to days
  now = div(now, 24)
  days = now % 365 # ± 365 days in a year
  return days, hours, minutes, seconds
end

### Fermat
function checkfermat(a::Int, b::Int, c::Int, n::Int)
  if a^n + b^n == c^n
      println("Holy smokes, Fermat was wrong!")
  else
      println("No, that doesn’t work.")
  end
end


### Justify
rightjustify(s) = println(" "^(70-length(s)) * s)

### Grid print
function printgrid()
  dashed = " -"^4*" "
  plusdash = "+"*dashed*"+"*dashed*"+"
  verticals = ("|"*" "^9)^2*"|"
  s = (plusdash * "\n" * (verticals * "\n")^4)^2*plusdash * "\n"
  println(s)
end

# WIP bigprint

#= Notebook 2: collections =# 
### Riemann sum

function riemannsum(f, a, b; n=100)
  dx = (b - a) / n
  return sum(f.(a:dx:b)) * dx
end

### Markdown table
function markdowntable(table, header)
  n, m = size(table)
  table_string = ""
  # add header
  table_string *= "| " * join(header, " | ") * " |\n"
  # horizontal lines for separating the columns
  table_string *= "| " * repeat(":--|", m) * "\n"
  for i in 1:n
      table_string *= "| " * join(table[i,:], " | ") * " |\n"
  end
  #clipboard(table_string)
  return table_string
end

### Determinant
# WIP

### Pi Time
function estimatepi(n)
  hits = 0
  for i in 1:n
      x = rand()
      y = rand()
      if x^2 + y^2 ≤ 1.0
          hits += 1
      end
  end
  return 4hits/n
end

estimatepi2(n) = 4count(x-> x ≤ 1.0, sum(rand(n, 2).^2, dims=2)) / n

### Vandermonde
vandermonde(α, n) = [αᵢ^j for αᵢ in α, j in 0:n-1]

#=______________________
|                       |
|         Day 2         |
|_______________________|
=#

#= Notebook 1: types =#
### String parsing
bunchofnumbers_parser(bunchofnumbers) = parse.(Float64, split(rstrip(bunchofnumbers), ", ")) |> sum


#= Notebook 2: composite types =#
### Wizarding currency

struct WizCur
  knuts::Int
  sickles::Int
  galleons::Int
  function WizCur(knuts::Int, sickles::Int, galleons::Int)
        knuts, sickles = knuts % 29, sickles + div(knuts, 29)
        sickles, galleons = sickles % 17, galleons + div(sickles, 17)
        new(knuts, sickles, galleons)
    end
end

Base.show(io::IO, wizcur::WizCur) = print("$(wizcur.knuts)K, $(wizcur.sickles)S, $(wizcur.galleons)G")


Base.:+(c1::WizCur, c2::WizCur) = WizCur(c1.knuts+c2.knuts, c1.sickles+c2.sickles, c1.galleons+c2.galleons)
knuts(c::WizCur) = c.knuts + 17c.sickles + 493c.galleons
Base.:>(c1::WizCur, c2::WizCur) = knuts(c1) > knuts(c2)
Base.:<(c1::WizCur, c2::WizCur) = knuts(c1) < knuts(c2)

money_ron = WizCur(732, 19, 0)
money_harry = WizCur(7, 1, 3)
money_harry > money_ron
