###############################################################################
#
#   LaurentPoly.jl : Generic Laurent polynomials over rings
#
###############################################################################

import AbstractAlgebra: terms_degrees
using AbstractAlgebra: term_degree, degrees_range, ismonomial_nonrec

###############################################################################
#
#   Data type and parent object methods
#
###############################################################################

parent_type(::Type{LaurentPolyWrap{T, PE}}) where {T, PE} =
   LaurentPolyWrapRing{T, parent_type(PE)}

elem_type(::Type{LaurentPolyWrapRing{T, PR}}) where {T, PR} =
   LaurentPolyWrap{T, elem_type(PR)}

parent(p::LaurentPolyWrap) = LaurentPolyWrapRing(parent(p.poly))

base_ring(R::LaurentPolyWrapRing) = base_ring(R.polyring)

var(R::LaurentPolyWrapRing) = var(R.polyring)

symbols(R::LaurentPolyWrapRing) = symbols(R.polyring)

nvars(R::LaurentPolyWrapRing) = nvars(R.polyring)

characteristic(R::LaurentPolyWrapRing) = characteristic(R.polyring)


###############################################################################
#
#   Basic manipulation
#
###############################################################################

terms_degrees(p::LaurentPolyWrap) = p.mindeg .+ (0:degree(p.poly))

coeff(p::LaurentPolyWrap, i::Int) =
   i < p.mindeg ? zero(base_ring(p)) : coeff(p.poly, i - p.mindeg)

function _enable_deg!(p::LaurentPolyWrap, i::Int)
   diff = p.mindeg - i
   if diff > 0
      p.mindeg = i
      p.poly = shift_left(p.poly, diff)
   end
   nothing
end

# the underlying storage is adjusted (increased) to allow setting the coeff
function setcoeff!(p::LaurentPolyWrap, i::Int, a)
   _enable_deg!(p, i)
   setcoeff!(p.poly, i - p.mindeg, a)
   p
end

iszero(p::LaurentPolyWrap) = iszero(p.poly)

isone(p::LaurentPolyWrap) = ismonomial_nonrec(p, 0)

zero(R::LaurentPolyWrapRing) = LaurentPolyWrap(zero(R.polyring))
one(R::LaurentPolyWrapRing) = LaurentPolyWrap(one(R.polyring))

gen(R::LaurentPolyWrapRing) = LaurentPolyWrap(gen(R.polyring))

isgen(p::LaurentPolyWrap) = ismonomial_nonrec(p, 1)

# only an optimization over the default Base implementation (maybe 1.4 speed-up)
deepcopy_internal(p::LaurentPolyWrap, dict::IdDict) =
   LaurentPolyWrap(deepcopy_internal(p.poly, dict), p.mindeg)


###############################################################################
#
#   Unary and Binary operations
#
###############################################################################

-(p::LaurentPolyWrap) = LaurentPolyWrap(-p.poly, p.mindeg)

function +(p::LaurentPolyWrap, q::LaurentPolyWrap)
   if p.mindeg > q.mindeg
      p, q = q, p
   end
   p_, q_ = p.poly, q.poly
   if p.mindeg < q.mindeg
      q_ = shift_left(q_, q.mindeg - p.mindeg)
   end
   LaurentPolyWrap(p_ + q_, p.mindeg)
end

-(p::LaurentPolyWrap, q::LaurentPolyWrap) = p + (-q) # TODO: optimize

*(p::LaurentPolyWrap, q::LaurentPolyWrap) = LaurentPolyWrap(p.poly * q.poly, p.mindeg + q.mindeg)

###############################################################################
#
#   Ad hoc binary operators
#
###############################################################################

*(p::LaurentPolyWrap{T}, a::T) where {T<:RingElem} = LaurentPolyWrap(p.poly * a, p.mindeg)
*(a::T, p::LaurentPolyWrap{T}) where {T<:RingElem} = p * a

*(p::LaurentPolyWrap, a::Union{Integer,Rational,AbstractFloat}) = LaurentPolyWrap(p.poly * a, p.mindeg)
*(a::Union{Integer,Rational,AbstractFloat}, p::LaurentPolyWrap) = p * a

+(p::LaurentPolyWrap, a::RingElement) = p + LaurentPolyWrap(one(p.poly) * a)
+(a::RingElement, p::LaurentPolyWrap) = p + a

###############################################################################
#
#   Powering
#
###############################################################################

function ^(p::LaurentPolyWrap, e::Integer)
   if e >= 0
      LaurentPolyWrap(p.poly^e, p.mindeg * e)
   else
      # p must be a term, whose coeff is invertible
      deg = term_degree(p)
      c = coeff(p, deg)
      # the following is to allow x^-3 even if 1^-3 is failing
      c = isone(c) ? c : c^e
      LaurentPolyWrap(c * one(p.poly), deg * e)
   end
end


###############################################################################
#
#   Evaluation
#
###############################################################################

function evaluate(p::LaurentPolyWrap, b::RingElement)
   z = evaluate(p.poly, b)
   s = b^p.mindeg
   s * z
end


###############################################################################
#
#   Unsafe functions
#
###############################################################################

function zero!(p::LaurentPolyWrap)
   q = zero!(p.poly)
   if q !== p.poly
      LaurentPolyWrap(q, 0)
   else
      p.mindeg = 0
      p
   end
end

function mul!(c::LaurentPolyWrap{T}, a::LaurentPolyWrap{T}, b::LaurentPolyWrap{T}) where T
   am = a.mindeg
   bm = b.mindeg
   d = mul!(c.poly, a.poly, b.poly)
   if d === c.poly
      c.mindeg = am + bm
      c
   else
      LaurentPolyWrap(d, am + bm)
   end
end

function addeq!(c::LaurentPolyWrap{T}, a::LaurentPolyWrap{T}) where T
   # TODO: optimize (together with +)
   d = c + a
   c.poly = d.poly
   c.mindeg = d.mindeg
   c
end

function add!(c::LaurentPolyWrap{T}, a::LaurentPolyWrap{T}, b::LaurentPolyWrap{T}) where T
   # TODO: optimize
   d = a + b
   c.poly = d.poly
   c.mindeg = d.mindeg
   c
end


###############################################################################
#
#   Random elements
#
###############################################################################

function rand(rng::AbstractRNG, S::LaurentPolyWrapRing, degrees_range, v...)
   m = minimum(degrees_range)
   degrees_range = degrees_range .- m
   LaurentPolyWrap(rand(rng, S.polyring, degrees_range, v...), m)
end

rand(S::LaurentPolyWrapRing, degrees_range, v...) =
   rand(Random.GLOBAL_RNG, S, degrees_range, v...)


###############################################################################
#
#   Promotion rules
#
###############################################################################

# TODO: add tests

promote_rule(::Type{L}, ::Type{L}) where {L <: LaurentPolyWrap} = L

function promote_rule(::Type{L}, ::Type{U}) where
       {T<:RingElement, L <: LaurentPolyWrap{T}, U <: RingElement}
   promote_rule(T, U) == T ? L : Union{}
end


################################################################################
#
#  map_coeffs
#
################################################################################

map_coeffs(f, p::LaurentPolyWrap) = LaurentPolyWrap(map_coeffs(f, p.poly), p.mindeg)

###############################################################################
#
#   Parent object call overload
#
###############################################################################

(R::LaurentPolyWrapRing)(b::RingElement) = LaurentPolyWrap(R.polyring(b))

(R::LaurentPolyWrapRing)() = LaurentPolyWrap(R.polyring())

function (R::LaurentPolyWrapRing)(p::LaurentPolyWrap)
   parent(p) == R ? p :
                    LaurentPolyWrap(R.polyring(p.poly), p.mindeg)
end

###############################################################################
#
#   LaurentPolynomialRing constructor
#
###############################################################################

@doc doc"""
    LaurentPolynomialRing(R::AbstractAlgebra.Ring, s::AbstractString)
> Given a base ring `R` and string `s` specifying how the generator (variable)
> should be printed, return a tuple `S, x` representing the new Laurent polynomial
> ring $S = R[x, 1/x]$ and the generator $x$ of the ring. The parent
> object `S` will depend only on `R` and `x`.
"""
function LaurentPolynomialRing(R::AbstractAlgebra.Ring, s::AbstractString)
   P, x = AbstractAlgebra.PolynomialRing(R, s)
   LaurentPolyWrapRing(P), LaurentPolyWrap(x)
end

###############################################################################
#
#   String I/O
#
###############################################################################

function show(io::IO, y::LaurentPolyWrap)
   x = y.poly
   mindeg = y.mindeg
   len = length(x)
   S = var(parent(x))
   if len == 0
      print(IOContext(io, :compact => true), base_ring(x)(0))
   else
      for i = 1:len
         c = coeff(x, len - i)
         bracket = needs_parentheses(c)
         if !iszero(c)
            if i != 1 && !displayed_with_minus_in_front(c)
               print(io, "+")
            end
            if len - i + mindeg != 0
               if !isone(c) && (c != -1 || show_minus_one(typeof(c)))
                  if bracket
                     print(io, "(")
                  end
                  print(IOContext(io, :compact => true), c)
                  if bracket
                     print(io, ")")
                  end
                  print(io, "*")
               end
               if c == -1 && !show_minus_one(typeof(c))
                  print(io, "-")
               end
               print(io, string(S))
               if len - i + mindeg != 1
                  print(io, "^")
                  print(io, len - i + mindeg)
               end
            else # constant term
               if bracket
                  print(io, "(")
               end
               print(IOContext(io, :compact => true), c)
               if bracket
                  print(io, ")")
               end
            end
         end
      end
   end
end
