###############################################################################
#
#   Integer.jl : Additional AbstractAlgebra functionality for Julia Integer
#
###############################################################################

###############################################################################
#
#   Data type and parent object methods
#
###############################################################################

const JuliaZZ = Integers{BigInt}()

const zz = Integers{Int}()

parent(a::T) where T <: Integer = Integers{T}()

elem_type(::Type{Integers{T}}) where T <: Integer = T

parent_type(::Type{T}) where T <: Integer = Integers{T}

base_ring(a::Integers{T}) where T <: Integer = Union{}

isexact_type(::Type{T}) where T <: Integer = true

isdomain_type(::Type{T}) where T <: Integer = true

###############################################################################
#
#   Basic manipulation
#
###############################################################################

zero(::Integers{T}) where T <: Integer = T(0)

one(::Integers{T}) where T <: Integer = T(1)

@doc Markdown.doc"""
    isunit(a::Integer)

Return `true` if $a$ is $1$ or $-1$.
"""
isunit(a::Integer) = a == 1 || a == -1

canonical_unit(a::T) where T <: Integer = a < 0 ? T(-1) : T(1)

characteristic(::Integers{T}) where T <: Integer = 0

###############################################################################
#
#   String I/O
#
###############################################################################

function expressify(a::Integer; context = nothing)
    return a
end

function show(io::IO, R::Integers)
   print(io, "Integers")
end

###############################################################################
#
#   Modular arithmetic
#
###############################################################################

function divrem(a::BigInt, b::BigInt)
   r = mod(a, b)
   q = Base.div(a - r, b)
   return q, r
end

function divrem(a::Int, b::Int)
   r = mod(a, b)
   q = Base.div(a - r, b)
   return q, r
end

function divrem(a::BigInt, b::Int)
   r = mod(a, b)
   q = Base.div(a - r, b)
   return q, r
end

function divrem(a::S, b::T) where {S <: Integer, T <: Integer}
   r = mod(a, b)
   q = Base.div(a - r, b)
   return q, r
end

function div(a::S, b::T) where {S <: Integer, T <: Integer}
   r = mod(a, b)
   q = Base.div(a - r, b)
   return q
end

function powmod(a::T, b::Int, c::T) where T <: Integer
   b < 0 && throw(DomainError(b, "exponent must be >= 0"))
   # special cases
   if a == 0
      return T(0)
   elseif b == 0
      return T(1)
   else
      bit = ~((~UInt(0)) >> 1)
      while (UInt(bit) & b) == 0
         bit >>= 1
      end
      z = mod(a, c)
      bit >>= 1
      while bit != 0
         z = mod(z*z, c)
         if (UInt(bit) & b) != 0
            z = mod(z*a, c)
         end
         bit >>= 1
      end
      return z
   end
end

function powmod(a::T, b::BigInt, c::T) where T <: Integer
   b < 0 && throw(DomainError(b, "exponent must be >= 0"))
   # special cases
   if a == 0
      return T(0)
   elseif b == 0
      return T(1)
   else
      n = ndigits(b; base = 2)
      bit = BigInt(1) << (n - 1)
      z = mod(a, c)
      bit >>= 1
      while bit != 0
         z = mod(z*z, c)
         if (bit & b) != 0
            z = mod(z*a, c)
         end
         bit >>= 1
      end
      return z
   end
end

###############################################################################
#
#   Divides
#
###############################################################################

function divides(a::T, b::T) where T <: Integer
   q, r = divrem(a, b)
   return r == 0, q
end

###############################################################################
#
#   Exact division
#
###############################################################################

function divexact(a::Integer, b::Integer)
   q, r = divrem(a, b)
   iszero(r) || throw(ArgumentError("not an exact division"))
   q
end

###############################################################################
#
#   Inverse
#
###############################################################################

function inv(a::T) where T <: Integer
   if a == 1
      return one(T)
   elseif a == -1
      return -one(T)
   end
   iszero(a) && throw(DivideError())
   throw(ArgumentError("not a unit"))
end

###############################################################################
#
#   GCD
#
###############################################################################

function gcdinv(a::T, b::T) where T <: Integer
   g, s, t = gcdx(a, b)
   return g, s
end

###############################################################################
#
#   Square root
#
###############################################################################

@doc Markdown.doc"""
    sqrt(a::T) where T <: Integer

Return the integer square root of $a$. If $a$ is not a perfect square an
exception is thrown. If `check` is set to `false` this check is not
performed.
"""
function sqrt(a::T, check::Bool=true) where T <: Integer
   s = isqrt(a)
   (check && s*s != a) && error("Not a square in sqrt")
   return s
end

@doc Markdown.doc"""
    issquare(a::T) where T <: Integer

Return true if $a$ is a square.
"""
function issquare(a::T) where T <: Integer
   if a < 0
      return false
   end
   s = isqrt(a)
   return a == s*s
end

###############################################################################
#
#   Exponential
#
###############################################################################

@doc Markdown.doc"""
    exp(a::T) where T <: Integer

Return $1$ if $a = 0$, otherwise throw an exception. This function is not
generally of use to the user, but is used internally in AbstractAlgebra.jl.
"""
function exp(a::T) where T <: Integer
    a != 0 && throw(DomainError(a, "a must be 0"))
    return T(1)
 end

###############################################################################
#
#   Coprime bases
#
###############################################################################

# Bernstein, "Factoring into coprimes in essentially linear time"
# ppio(a,b) = (c,n) where v_p(c) = v_p(a) if v_p(b) != 0, 0 otherwise
# c*n = a or c = gcd(a, b^infty), n = div(a, c).
# This is used in various Euclidean domains for Chinese remaindering.

@doc Markdown.doc"""
    ppio(a::T, b::T)

Split $a$ into $c*d$ where $c = gcd(a, b^\infty)$.
"""
function ppio(a::T, b::T) where T <: Integer
   c = gcd(a, b)
   n = div(a, c)
   g = gcd(c, n)
   while !isone(g)
      c *= g
      n = div(n, g)
      g = gcd(c, n)
   end
   return c, n
end

###############################################################################
#
#   Primality test
#
###############################################################################

function isprobable_prime(x::Integer, reps::Integer=25)
   return ccall((:__gmpz_probab_prime_p, :libgmp), Cint,
                (Ref{BigInt}, Cint), x, reps) != 0
end

###############################################################################
#
#   Unsafe functions
#
###############################################################################

function zero!(a::Integer)
   return 0
end

function zero!(a::BigInt)
   ccall((:__gmpz_set_si, :libgmp), Nothing, (Ref{BigInt}, Int), a, 0)
   return a
end

function mul!(a::T, b::T, c::T) where T <: Integer
   return b*c
end

function mul!(a::BigInt, b::BigInt, c::BigInt)
   ccall((:__gmpz_mul, :libgmp), Nothing, (Ref{BigInt}, Ref{BigInt}, Ref{BigInt}), a, b, c)
   return a
end

function add!(a::T, b::T, c::T) where T <: Integer
   return b + c
end

function add!(a::BigInt, b::BigInt, c::BigInt)
   ccall((:__gmpz_add, :libgmp), Nothing, (Ref{BigInt}, Ref{BigInt}, Ref{BigInt}), a, b, c)
   return a
end

function addeq!(a::T, b::T) where T <: Integer
   return a + b
end

function addeq!(a::BigInt, b::BigInt)
   ccall((:__gmpz_add, :libgmp), Nothing, (Ref{BigInt}, Ref{BigInt}, Ref{BigInt}), a, a, b)
   return a
end

function addmul!(a::T, b::T, c::T, d::T) where T <: Integer
   return a + b*c
end

function addmul!(a::BigInt, b::BigInt, c::BigInt, d::BigInt)
   ccall((:__gmpz_addmul, :libgmp), Nothing, (Ref{BigInt}, Ref{BigInt}, Ref{BigInt}), a, b, c)
   return a
end

function addmul!(a::T, b::T, c::T) where T <: Integer # special case, no temporary required
   return a + b*c
end

function addmul!(a::BigInt, b::BigInt, c::BigInt) # special case, no temporary required
   ccall((:__gmpz_addmul, :libgmp), Nothing, (Ref{BigInt}, Ref{BigInt}, Ref{BigInt}), a, b, c)
   return a
end

###############################################################################
#
#   Random generation
#
###############################################################################

RandomExtensions.maketype(R::AbstractAlgebra.Integers{T}, _) where {T} = T

# define rand(make(ZZ, n:m))
rand(rng::AbstractRNG,
     sp::SamplerTrivial{<:Make2{T, Integers{T}, UnitRange{Int}}}
     ) where {T} =
        sp[][1](rand(rng, sp[][2]))


rand(rng::AbstractRNG, R::Integers, n) = R(rand(rng, n))

rand(R::Integers, n) = rand(Random.GLOBAL_RNG, R, n)

###############################################################################
#
#   Parent object call overload
#
###############################################################################

function (a::Integers{T})() where T <: Integer
   return T(0)
end

function (a::Integers{T})(b::Integer) where T <: Integer
   return T(b)
end
