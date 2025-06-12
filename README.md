# Cryptography in Zig

A collection of cryptographic algorithms implemented from scratch in [Zig](https://ziglang.org/). Starting with SHA-1, with more to come.

## 📦 Current Implementations
- **SHA-1** - Secure Hash Algorithm 1 (FIPS 180-4)

## 🚧 Coming Soon
- SHA-256
- SipHash
- HMAC

## 🛠️ Building & Running
1. Ensure you have [Zig 0.11+](https://ziglang.org/download/) installed
2. Clone the repository:
   ```sh
   git clone https://github.com/rohitanwar/Cryptography.git
   cd Cryptography
   ```
3. Run the SHA-1 implementation:
   ```sh
   zig run src/sha1.zig
   ```
> **⚠️ Warning**  
> Currently the build.zig doesn't work. You need to manually enter the string to hash in the `src/sha1.zig` file


## 🤝 Contributing
Contributions are welcome! Please open an issue or PR if you:

- Find a bug

- Want to add another algorithm

- Have optimization suggestions
