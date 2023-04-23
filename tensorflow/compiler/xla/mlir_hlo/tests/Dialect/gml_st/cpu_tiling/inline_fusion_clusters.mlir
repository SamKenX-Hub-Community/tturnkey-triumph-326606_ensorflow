// RUN: mlir-hlo-opt %s --gml-st-inline-fusion-clusters \
// RUN:   --split-input-file \
// RUN: | FileCheck %s

func.func @two_clusters_tensors(
    %arg0: tensor<?x?xf32>, %arg1: tensor<?x?xf32>, %arg2: tensor<?xf32>)
    -> tensor<?xf32> {
  %0 = gml_st.fusion ins(%arg3 = %arg0: tensor<?x?xf32>)
                     inits(%arg4 = %arg1: tensor<?x?xf32>) {
    %sorted0 = thlo.sort
      ins(%arg3 : tensor<?x?xf32>)
      outs(%arg4 : tensor<?x?xf32>)
      dimension = 0
      is_stable = false
      (%lhs0: f32, %rhs0: f32) {
        %2 = arith.cmpf ogt, %lhs0, %rhs0 : f32
        thlo.yield %2 : i1
      }
    gml_st.yield %sorted0 : tensor<?x?xf32>
  } : tensor<?x?xf32>
  %1 = gml_st.fusion ins(%arg3 = %0: tensor<?x?xf32>)
                     inits(%arg4 = %arg2: tensor<?xf32>) {
    %reduced = linalg.reduce { arith.addf } ins(%arg3 : tensor<?x?xf32>) outs(%arg4 : tensor<?xf32>) dimensions = [0]
    %mapped = linalg.map { math.exp } ins(%reduced : tensor<?xf32>) outs(%arg4 : tensor<?xf32>)
    gml_st.yield %mapped : tensor<?xf32>
  } : tensor<?xf32>
  return %1 : tensor<?xf32>
}

// CHECK-LABEL: @two_clusters_tensors
// CHECK-NOT:   gml_st.fusion
// CHECK:       thlo.sort
// CHECK-NOT:   gml_st.fusion
// CHECK:       linalg.reduce
// CHECK:       linalg.map

// -----

func.func @two_clusters_memrefs(
    %arg0: memref<?x?xf32>, %arg1: memref<?x?xf32>, %arg2: memref<?xf32>)
    -> memref<?xf32> {
  gml_st.fusion ins(%arg3 = %arg0: memref<?x?xf32>)
                inits(%arg4 = %arg1: memref<?x?xf32>) {
    thlo.sort
      ins(%arg3 : memref<?x?xf32>)
      outs(%arg4 : memref<?x?xf32>)
      dimension = 0
      is_stable = false
      (%lhs0: f32, %rhs0: f32) {
        %2 = arith.cmpf ogt, %lhs0, %rhs0 : f32
        thlo.yield %2 : i1
      }
    gml_st.yield %arg4 : memref<?x?xf32>
  }
  gml_st.fusion ins(%arg3 = %arg1: memref<?x?xf32>)
                inits(%arg4 = %arg2: memref<?xf32>) {
    linalg.reduce { arith.addf }
      ins(%arg3 : memref<?x?xf32>)
      outs(%arg4 : memref<?xf32>)
      dimensions = [0]
    linalg.map { math.exp }
      ins(%arg4 : memref<?xf32>)
      outs(%arg4 : memref<?xf32>)
    gml_st.yield %arg4 : memref<?xf32>
  }
  return %arg2 : memref<?xf32>
}

// CHECK-LABEL: @two_clusters_memrefs
// CHECK-NOT:   gml_st.fusion
// CHECK:       thlo.sort
// CHECK-NOT:   gml_st.fusion
// CHECK:       linalg.reduce
// CHECK:       linalg.map
