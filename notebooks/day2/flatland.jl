### A Pluto.jl notebook ###
# v0.12.18

using Markdown
using InteractiveUtils

# ╔═╡ 63f5861e-6244-11eb-268b-a16bc3f8265c
using DSJulia

# ╔═╡ b1d21552-6242-11eb-2665-c9232be7026e
md"""
# Flatland

## Introduction and goal
In this notebook, we will implement a variety of two-dimensional geometric shapes.
The different shapes might have drastically different representations. For example, we can describe a rectangle
by the coordinates of its center, its length and its width. A triangle, on the other hand,
is more naturally represented by its three points. Similarly, computing the area of a rectangle or a triangle
involves two different formulas. The nice thing about Julia is that you can hide this complexity from the users.
You have to create your structures, subtypes of the abstract `Shape` type and have custom methods that will work
for each type!

Below, we suggest a variety of shapes, each with its unique representation. For this assignment, you have to complete **one**
type and make sure all the provided functions `corners`, `area`, `move!`, `rotate!`,... work. Using `PlottingRecipes`, you can easily
plot all your shapes (provided you implemented all the helper functions).

Implementing such shapes can have various exciting applications, such as making a drawing tool or a ray tracer. Our
end goal is to implement a simulator of a toy statistical physics system. Here, we simulate a system with inert particles, leading to self-organization.
Our simple rejection sampling algorithm that we will use is computationally very demanding, an ideal case study for Julia!

## Assignments

- [ ] add the correct *inner* constructor to your type;
- [ ] complete `corners` and `ncorners`, which return the corners and the number of corners, respecitively;
- [ ] complete `center` to return the center of mass of the shape;
- [ ] complete `xycoords`, which give two vectors with the x- and y-coordinates of the shape, used for plotting;
- [ ] complete `xlim` and `ylim` to give the range on the x- and y-axes of your shape, in addition to `boundingbox` to generate a bounding box of your shape;
- [ ] complete `area`, this computes the area of your shape;
- [ ] complete `move!`, `rotate!` and `scale!` to transform your shape **in place** (note: `AbstractRectangle`s cannot be rotated, they are always aligned to the axes);
- [ ] complete the function `in`, to check whether a point is in your shape;
- [ ] complete `intersect`, to check whether two shapes overlap;
- [ ] complete `randplace!`, which randomly moves and rotates a shape within a box;
- [ ] complete the rejection sampling algorithm and experiment with your shape(s).

Note: You will need to create specifice methods for different types. It's your job to split the template for the functions in several methods and use dispatch.
"""

# ╔═╡ d65b61ba-6242-11eb-030d-b18a7518731b
md"## Types
We define all kinds of shapes. For the constructors, we follow the convention: `Shape((x,y); kwargs)` where `kwargs` are the keyword arguments determining
the shape.
"

# ╔═╡ e3f846c8-6242-11eb-0d12-ed9f7e534db8
abstract type Shape end

# ╔═╡ e7e43620-6242-11eb-1e2e-65874fe8e293
md"""
 `AbstractRectangle` is for simple rectangles and squares, for which the sides are always aligned with the axes.
They have a `l`ength and `w`idth attribute, in addtion to an `x` and `y` for their center.


"""

# ╔═╡ f4b05730-6242-11eb-0e24-51d4c60dc451
abstract type AbstractRectangle <: Shape end

# ╔═╡ fe413efe-6242-11eb-3c38-13b9d996bc90
begin
	mutable struct Rectangle <: AbstractRectangle
		x::Float64
		y::Float64
		l::Float64
		w::Float64
		function Rectangle((x, y); l=1.0, w=1.0)
			return new(x, y, l, w)
		end
	end
	
	function Rectangle((xmin, xmax), (ymin, ymax))
		@assert xmin < xmax && ymin < ymax "Corners have to be ordered: `xmin < xmax && ymin < ymax `"
		x = (xmin + xmax) / 2
		y = (ymin + ymax) / 2
		l = xmax - xmin
		w = ymax - ymin
		return Rectangle((x, y), l=l, w=w)
	end
end

# ╔═╡ 12ddaece-6243-11eb-1e9d-2be312d2e22d
md"Squares are special cases."

# ╔═╡ 16666cac-6243-11eb-0e0f-dd0d0ec53926
mutable struct Square <: AbstractRectangle
    x::Float64
    y::Float64
    l::Float64
    function Square((x, y); l=1.0)
        return new(x, y, l)
    end
end

# ╔═╡ 23ea0a46-6243-11eb-145a-b38e34969cfd
md"This small function to get `l` and `w` will allow you to treat `Square` and `Rectangle` the same!"

# ╔═╡ 1b129bf4-6243-11eb-1fa2-d7bd5563a1b4
begin
	lw(shape::Rectangle) = shape.l, shape.w
	lw(shape::Square) = shape.l, shape.l
end

# ╔═╡ 2ba1f3e6-6243-11eb-0f18-ef5e21e01a15
md"Regular polygons have a center (`x`, `y`), a radius `R` (distance center to one of the corners) and an angle `θ` how it it tilted.
The order of the polygon is part of its parametric type, so we give the compiler some hint how it will behave."

# ╔═╡ 33757f2c-6243-11eb-11c2-ab5bbd90aa6b
mutable struct RegularPolygon{N} <: Shape 
    x::Float64
    y::Float64
    R::Float64
    θ::Float64  # angle
    function RegularPolygon((x, y), n::Int; R=1.0, θ=0.0)
        @assert n ≥ 3 "polygons need a minimum of three corners"
        return new{n}(x, y, R, θ)
    end
end

# ╔═╡ 381d19b8-6243-11eb-2477-5f0e919ff7bd
md"`Circle`s are pretty straightforward, having a center and a radius."

# ╔═╡ 3d67d61a-6243-11eb-1f83-49032ad146da
mutable struct Circle <: Shape
    x::Float64
    y::Float64
    R::Float64
    function Circle((x, y); R=1.0)
        return new(x, y, R)
    end
end

# ╔═╡ 4234b198-6243-11eb-2cfa-6102bfd9b896
md"Triangles are described by its three points. Its center is computed when needed."

# ╔═╡ 473d9b5c-6243-11eb-363d-23108e81eb93
abstract type AbstractTriangle <: Shape end

# ╔═╡ 50e45ac6-6243-11eb-27f9-d5e7d0e1dc01
mutable struct Triangle <: AbstractTriangle
    x1::Float64
    x2::Float64
    x3::Float64
    y1::Float64
    y2::Float64
    y3::Float64
    Triangle((x1, y1), (x2, y2), (x3, y3)) = new(x1, x2, x3, y1, y2, y3)
end

# ╔═╡ 55de4f76-6243-11eb-1445-a54d01242f64
rect = Rectangle((1, 2), l=1, w=2)

# ╔═╡ 5b6b9854-6243-11eb-2d5b-f3e41ecf2914
square = Square((0, 1))

# ╔═╡ 5f120f1a-6243-11eb-1448-cb12a75680b0
triangle = Triangle((1, 2), (4, 5), (7, -10))

# ╔═╡ 64fcb6a0-6243-11eb-1b35-437e8e0bfac8
pent = RegularPolygon((0, 0), 5)

# ╔═╡ 668f568a-6243-11eb-3f01-adf1b603e0e4
hex = RegularPolygon((1.2, 3), 6)

# ╔═╡ 7b785b7a-6243-11eb-31c2-9d9deea78842
circle = Circle((10, 10))

# ╔═╡ 9b94fb66-6243-11eb-2635-6b2021c741f0
myshape = missing

# ╔═╡ 7c80d608-6243-11eb-38ba-f97f7476b245
md"""
## Corners and center
Some very basic functions to get or generate the corners and centers of your shapes. The corners are returned as a list of tuples, e.g. `[(x1, y1), (x2, y2),...]`.
"""

# ╔═╡ a005992e-6243-11eb-3e29-61c19c6e5c7c
begin
	ncorners(::Circle) = 0  # this one is for free!
	ncorners(shape::Shape) = missing
	
end

# ╔═╡ ac423fa8-6243-11eb-1385-a395d208c42d
begin
	function corners(shape::Shape)
		return missing
	end
end

# ╔═╡ ddf0ac38-6243-11eb-3a1d-cd39d70b2ee0
begin
	center(shape::Shape) = (missing, missing)
end

# ╔═╡ ecc9a53e-6243-11eb-2784-ed46ccbcadd2
begin
	xycoords(s::Shape) = missing, missing

	function xycoords(shape::Circle; n=50)
		# compute `n` points of the circle
		return missing, missing
	end
end

# ╔═╡ 5de0c912-6244-11eb-13fd-bfd8328191a6
md"""
## x,y-bounding

The fuctions below yield the outer limits of the x and y axes of your shape. Can you complete the methods with a oneliner?
"""

# ╔═╡ 9ef18fda-6244-11eb-3751-5344dff96d3e
hint(md"The function `extrema` could be useful here...")

# ╔═╡ a89bdba6-6244-11eb-0b83-c1c64e4de17d
begin
	xlim(shape::Shape) = missing
end

# ╔═╡ b1372784-6244-11eb-0279-27fd755cda6a
begin
	ylim(shape::Shape) = missing
end

# ╔═╡ bd706964-6244-11eb-1d9d-2b60e53cdce1
md"This returns the bounding box, as the smallest rectangle that can completely contain your shape."

# ╔═╡ b91e1e62-6244-11eb-1045-0770fa92e040
boundingbox(shape::Shape) = missing

# ╔═╡ d60f8ca4-6244-11eb-2055-4551e4c10906


# ╔═╡ f69370bc-6244-11eb-290e-fdd4d7cc826a
hint(md"The area of a triangle can be computed as $${\frac {1}{2}}{\big |}(x_{A}-x_{C})(y_{B}-y_{A})-(x_{A}-x_{B})(y_{C}-y_{A}){\big |}$$.")

# ╔═╡ 69780926-6245-11eb-3442-0dc8aea8cb73
hint(md"A regular polygon consists of a couple of isosceles triangles.")

# ╔═╡ ebf4a45a-6244-11eb-0965-197f536f8e87


# ╔═╡ Cell order:
# ╠═63f5861e-6244-11eb-268b-a16bc3f8265c
# ╠═b1d21552-6242-11eb-2665-c9232be7026e
# ╠═d65b61ba-6242-11eb-030d-b18a7518731b
# ╠═e3f846c8-6242-11eb-0d12-ed9f7e534db8
# ╠═e7e43620-6242-11eb-1e2e-65874fe8e293
# ╠═f4b05730-6242-11eb-0e24-51d4c60dc451
# ╠═fe413efe-6242-11eb-3c38-13b9d996bc90
# ╠═12ddaece-6243-11eb-1e9d-2be312d2e22d
# ╠═16666cac-6243-11eb-0e0f-dd0d0ec53926
# ╠═23ea0a46-6243-11eb-145a-b38e34969cfd
# ╠═1b129bf4-6243-11eb-1fa2-d7bd5563a1b4
# ╠═2ba1f3e6-6243-11eb-0f18-ef5e21e01a15
# ╠═33757f2c-6243-11eb-11c2-ab5bbd90aa6b
# ╠═381d19b8-6243-11eb-2477-5f0e919ff7bd
# ╠═3d67d61a-6243-11eb-1f83-49032ad146da
# ╠═4234b198-6243-11eb-2cfa-6102bfd9b896
# ╠═473d9b5c-6243-11eb-363d-23108e81eb93
# ╠═50e45ac6-6243-11eb-27f9-d5e7d0e1dc01
# ╠═55de4f76-6243-11eb-1445-a54d01242f64
# ╠═5b6b9854-6243-11eb-2d5b-f3e41ecf2914
# ╠═5f120f1a-6243-11eb-1448-cb12a75680b0
# ╠═64fcb6a0-6243-11eb-1b35-437e8e0bfac8
# ╠═668f568a-6243-11eb-3f01-adf1b603e0e4
# ╠═7b785b7a-6243-11eb-31c2-9d9deea78842
# ╠═9b94fb66-6243-11eb-2635-6b2021c741f0
# ╠═7c80d608-6243-11eb-38ba-f97f7476b245
# ╠═a005992e-6243-11eb-3e29-61c19c6e5c7c
# ╠═ac423fa8-6243-11eb-1385-a395d208c42d
# ╠═ddf0ac38-6243-11eb-3a1d-cd39d70b2ee0
# ╠═ecc9a53e-6243-11eb-2784-ed46ccbcadd2
# ╠═5de0c912-6244-11eb-13fd-bfd8328191a6
# ╠═9ef18fda-6244-11eb-3751-5344dff96d3e
# ╠═a89bdba6-6244-11eb-0b83-c1c64e4de17d
# ╠═b1372784-6244-11eb-0279-27fd755cda6a
# ╠═bd706964-6244-11eb-1d9d-2b60e53cdce1
# ╠═b91e1e62-6244-11eb-1045-0770fa92e040
# ╠═d60f8ca4-6244-11eb-2055-4551e4c10906
# ╠═f69370bc-6244-11eb-290e-fdd4d7cc826a
# ╠═69780926-6245-11eb-3442-0dc8aea8cb73
# ╠═ebf4a45a-6244-11eb-0965-197f536f8e87
