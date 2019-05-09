###############################################################################
#
#   Submodule.jl : Submodules of modules
#
###############################################################################

export Submodule, submodule_elem, ngens, gens, supermodule

###############################################################################
#
#   Basic manipulation
#
###############################################################################

parent_type(::Type{submodule_elem{T}}) where T <: RingElement = Submodule{T}

elem_type(::Type{Submodule{T}}) where T <: RingElement = submodule_elem{T}

parent(v::submodule_elem) = v.parent

base_ring(N::Submodule{T}) where T <: RingElement = N.base_ring

base_ring(v::submodule_elem{T}) where T <: RingElement = base_ring(v.parent)

ngens(N::Submodule{T}) where T <: RingElement = length(N.gens)

gens(N::Submodule{T}) where T <: RingElement = [gen(N, i) for i = 1:ngens(N)]

function gen(N::Submodule{T}, i::Int) where T <: RingElement
   R = base_ring(N)
   return N([(j == i ? one(R) : zero(R)) for j = 1:ngens(N)])
end

@doc Markdown.doc"""
    supermodule(M::Submodule{T}) where T <: RingElement
> Return the module that this module is a submodule of.
"""
supermodule(M::Submodule{T}) where T <: RingElement = M.m

function check_parent(v1::submodule_elem{T}, v2::submodule_elem{T}) where T <: RingElement
   parent(v1) !== parent(v2) && error("Incompatible module elements")
end

###############################################################################
#
#   String I/O
#
###############################################################################

function show(io::IO, N::Submodule{T}) where T <: RingElement
   println(io, "Submodule of:")
   print(IOContext(io, :compact => true), N.m)
   println(io, "")
   println(io, " with generators:")
   print(IOContext(io, :compact => true), N.gens)
end

function show(io::IO, N::Submodule{T}) where T <: FieldElement
   println(io, "Subspace of:")
   print(IOContext(io, :compact => true), N.m)
   println(io, "")
   println(io, " with generators:")
   print(IOContext(io, :compact => true), N.gens)
end

function show(io::IO, v::submodule_elem)
   print(io, "(")
   len = ngens(parent(v))
   for i = 1:len - 1
      print(IOContext(io, :compact => true), v.v[1, i])
      print(io, ", ")
   end
   if len > 0
      print(IOContext(io, :compact => true), v.v[1, len])
   end
   print(io, ")")
end

###############################################################################
#
#   Unary operators
#
###############################################################################

function -(v::submodule_elem{T}) where T <: RingElement
   N = parent(v)
   return N(-v.v)
end

###############################################################################
#
#   Binary operators
#
###############################################################################

function +(v1::submodule_elem{T}, v2::submodule_elem{T}) where T <: RingElement
   check_parent(v1, v2)
   N = parent(v1)
   return N(v1.v + v2.v)
end

function -(v1::submodule_elem{T}, v2::submodule_elem{T}) where T <: RingElement
   check_parent(v1, v2)
   N = parent(v1)
   return N(v1.v - v2.v)
end

###############################################################################
#
#   Ad hoc binary operators
#
###############################################################################

function *(v::submodule_elem{T}, c::T) where T <: RingElem
   N = parent(v)
   return N(v.v*c)
end

function *(v::submodule_elem{T}, c::U) where {T <: RingElement, U <: Union{Rational, Integer}}
   N = parent(v)
   return N(v.v*c)
end

function *(c::T, v::submodule_elem{T}) where T <: RingElem
   N = parent(v)
   return N(c*v.v)
end

function *(c::U, v::submodule_elem{T}) where {T <: RingElement, U <: Union{Rational, Integer}}
   N = parent(v)
   return N(c*v.v)
end

###############################################################################
#
#   Comparison
#
###############################################################################

function ==(m::submodule_elem{T}, n::submodule_elem{T}) where T <: RingElement
   check_parent(m, n)
   return m.v == n.v
end

###############################################################################
#
#   Parent object call overload
#
###############################################################################

function (N::Submodule{T})(v::Vector{T}) where T <: RingElement
   length(v) != ngens(N) && error("Length of vector does not match number of generators")
   mat = matrix(base_ring(N), 1, length(v), v)
   mat = reduce_mod_rels(mat, relations(N))
   return submodule_elem{T}(N, mat)
end

function (N::Submodule{T})(v::AbstractAlgebra.MatElem{T}) where T <: RingElement
   ncols(v) != ngens(N) && error("Length of vector does not match number of generators")
   nrows(v) != 1 && ("Not a vector in submodule_elem constructor")
   v = reduce_mod_rels(v, relations(N))
   return submodule_elem{T}(N, v)
end

###############################################################################
#
#   Submodule constructor
#
###############################################################################

reduced_form(mat::AbstractAlgebra.MatElem{T}) where T <: RingElement = hnf(mat)

function reduced_form(mat::AbstractAlgebra.MatElem{T}) where T <: FieldElement
  r, m = rref(mat)
  return mat
end

@doc Markdown.doc"""
    Submodule(m::AbstractAlgebra.FPModule{T}, gens::Vector{<:AbstractAlgebra.FPModuleElem{T}}) where T <: RingElement
> Return the submodule of the module `m` generated by the given generators,
> given as elements of `m`.
"""
function Submodule(m::AbstractAlgebra.FPModule{T}, gens::Vector{<:AbstractAlgebra.FPModuleElem{T}}) where T <: RingElement
   R = base_ring(m)
   r = length(gens)
   while r > 0 && iszero_row(gens[r].v, 1) # check that not all gens are zero
      r -= 1
   end
   if r == 0
      A = matrix(R, 0, 0, []) # needed only for its type
      T1 = typeof(A)
      M = Submodule{T}(m, gens, Vector{T1}(undef, 0),
                       Vector{Int}(undef, 0), Vector{Int}(undef, 0))
      f = map_from_func(M, m, x -> zero(m))
      M.map = f
      return M, f
   end
   # Make generators rows of a matrix
   s = ngens(m)
   mat = matrix(base_ring(m), r, s, [0 for i in 1:r*s])
   for i = 1:r
      parent(gens[i]) !== m && error("Incompatible module elements")
      for j = 1:s
         mat[i, j] = gens[i].v[1, j]
      end
   end
   # Reduce matrix (hnf/rref)
   mat = reduced_form(mat)
   # Remove zero rows
   num = r
   while num > 0
      rowzero = true
      for j = 1:s
         if mat[num, j] != 0
            rowzero = false
         end
      end
      if !rowzero
         break
      end
      num -= 1
   end
   # Rewrite matrix without zero rows and add old relations as rows
   old_rels = relations(m)
   if num != r || length(old_rels) != 0
      new_mat = matrix(base_ring(m), num + length(old_rels), s,
                                  [0 for i in 1:(num + length(old_rels))*s])
      for i = 1:num
         for j = 1:s
            new_mat[i, j] = mat[i, j]
         end
      end
      for i = 1:length(old_rels)
         for j = 1:s
            new_mat[i + num, j] = old_rels[i][1, j]
         end
      end
      mat = new_mat
   end
   # Rewrite old relations in terms of generators of new submodule
   num_rels, K = left_kernel(mat)
   new_rels = matrix(base_ring(m), num_rels, num, [0 for i in 1:num_rels*num])
   for j = 1:num_rels
      for k = 1:num
         new_rels[j, k] = K[j, k]
      end
   end
   # Compute reduced form of new rels
   new_rels = reduced_form(new_rels)
   # remove rows and columns corresponding to unit pivots
   gen_cols, culled, pivots = cull_matrix(new_rels)
   # put all the culled relations into new relations
   T1 = typeof(new_rels)
   rels = Vector{T1}(undef, length(culled))
   for i = 1:length(culled)
      rels[i] = matrix(R, 1, length(gen_cols),
                    [new_rels[culled[i], gen_cols[j]]
                       for j in 1:length(gen_cols)])
   end
   # Make submodule whose generators are the nonzero rows of mat
   nonzero_gens = [m([mat[i, j] for j = 1:s]) for i = 1:num]
   M = Submodule{T}(m, nonzero_gens, rels, gen_cols, pivots)
   # Compute map from elements of submodule into original module
   f = map_from_func(M, m, x -> sum(x.v[1, i]*nonzero_gens[gen_cols[i]] for i in 1:ncols(x.v)))
   M.map = f
   return M, f
end
