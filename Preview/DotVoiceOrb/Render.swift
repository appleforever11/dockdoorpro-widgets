import AppKit
import Metal
import SwiftUI
@main struct Render {
 @MainActor static func main() throws {
  guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else { fatalError("Metal unavailable") }
  let source = try String(contentsOfFile: "Widgets/DotGlass/DotVoiceOrb.swift", encoding: .utf8).components(separatedBy: "private static let shader = \"\"\"")[1].components(separatedBy: "\"\"\"")[0]
  let library = try device.makeLibrary(source: source, options: nil)
  let descriptor = MTLRenderPipelineDescriptor(); descriptor.vertexFunction = library.makeFunction(name: "orbVertex"); descriptor.fragmentFunction = library.makeFunction(name: "orbFragment"); descriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
  let pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
  for theme in DotTheme.allCases {
   let td = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 320, height: 320, mipmapped: false); td.storageMode = .shared; td.usage = .renderTarget
   let texture = device.makeTexture(descriptor: td)!
   let pass = MTLRenderPassDescriptor(); pass.colorAttachments[0].texture = texture; pass.colorAttachments[0].loadAction = .clear; pass.colorAttachments[0].storeAction = .store
   let command = queue.makeCommandBuffer()!, encoder = command.makeRenderCommandEncoder(descriptor: pass)!
   func rgba(_ color: Color) -> SIMD4<Float> { let c=NSColor(color).usingColorSpace(.deviceRGB)!;return SIMD4(Float(c.redComponent),Float(c.greenComponent),Float(c.blueComponent),1) }
   var uniforms = [SIMD4<Float>(20,320,0,0), SIMD4<Float>(0.22,1,0.008,0)] + theme.colors.map(rgba)
   encoder.setRenderPipelineState(pipeline);encoder.setFragmentBytes(&uniforms,length:uniforms.count*16,index:0);encoder.drawPrimitives(type:.triangle,vertexStart:0,vertexCount:3);encoder.endEncoding();command.commit();command.waitUntilCompleted()
   guard command.status == .completed else { fatalError("GPU render failed") }
   let bitmap = NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:320,pixelsHigh:320,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:1280,bitsPerPixel:32)!
   texture.getBytes(bitmap.bitmapData!,bytesPerRow:1280,from:MTLRegionMake2D(0,0,320,320),mipmapLevel:0)
   try bitmap.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"/tmp/dot-orb-reference/\(theme.rawValue).png"))
  }
 }
}
