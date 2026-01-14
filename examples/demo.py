#!/usr/bin/env python3
"""
Python-NoAdmin Demo Script

This script verifies that your Python-NoAdmin installation is working correctly.
It tests Python execution, pip availability, package installation, and virtual
environment creation.

Run with: python examples/demo.py
"""

import sys
import os
import subprocess
import tempfile
import shutil


def print_header(text):
    """Print a formatted header."""
    print()
    print("=" * 60)
    print(f"  {text}")
    print("=" * 60)
    print()


def print_success(text):
    """Print success message."""
    print(f"✅ {text}")


def print_error(text):
    """Print error message."""
    print(f"❌ {text}")


def print_info(text):
    """Print info message."""
    print(f"ℹ️  {text}")


def test_python_info():
    """Display Python installation information."""
    print_header("Python Installation Info")
    
    print_success(f"Python version: {sys.version}")
    print_success(f"Executable: {sys.executable}")
    print_success(f"Platform: {sys.platform}")
    print_success(f"Prefix: {sys.prefix}")
    
    # Check if running from user directory (not system Python)
    home = os.path.expanduser("~")
    if home in sys.executable:
        print_success("Running from user directory (not system Python)")
    else:
        print_info("Note: May be running from system Python")
    
    return True


def test_pip():
    """Test pip availability."""
    print_header("Testing pip")
    
    try:
        result = subprocess.run(
            [sys.executable, "-m", "pip", "--version"],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            print_success(f"pip available: {result.stdout.strip()}")
            return True
        else:
            print_error(f"pip failed: {result.stderr}")
            return False
    except Exception as e:
        print_error(f"pip test failed: {e}")
        return False


def test_package_installation():
    """Test installing a package."""
    print_header("Testing Package Installation")
    
    # Use a small, pure-Python package for testing
    test_package = "six"  # Small, widely used package
    
    print_info(f"Installing test package: {test_package}")
    
    try:
        # Install
        result = subprocess.run(
            [sys.executable, "-m", "pip", "install", "--quiet", test_package],
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            print_error(f"Installation failed: {result.stderr}")
            return False
        
        # Verify import
        result = subprocess.run(
            [sys.executable, "-c", f"import {test_package}; print({test_package}.__version__)"],
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            print_success(f"Package '{test_package}' installed and importable (version: {result.stdout.strip()})")
            return True
        else:
            print_error(f"Import failed: {result.stderr}")
            return False
            
    except Exception as e:
        print_error(f"Package installation test failed: {e}")
        return False


def test_venv():
    """Test virtual environment creation."""
    print_header("Testing Virtual Environment")
    
    # Create temp directory for venv
    temp_dir = tempfile.mkdtemp(prefix="python_nonadmin_test_")
    venv_path = os.path.join(temp_dir, "test_venv")
    
    try:
        print_info(f"Creating virtual environment at: {venv_path}")
        
        # Create venv
        result = subprocess.run(
            [sys.executable, "-m", "venv", venv_path],
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            print_error(f"venv creation failed: {result.stderr}")
            return False
        
        # Check venv structure
        if sys.platform == "win32":
            venv_python = os.path.join(venv_path, "Scripts", "python.exe")
        else:
            venv_python = os.path.join(venv_path, "bin", "python")
        
        if os.path.exists(venv_python):
            print_success(f"Virtual environment created successfully")
            print_success(f"venv Python: {venv_python}")
            
            # Test venv Python
            result = subprocess.run(
                [venv_python, "--version"],
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                print_success(f"venv Python works: {result.stdout.strip()}")
                return True
            else:
                print_error(f"venv Python test failed: {result.stderr}")
                return False
        else:
            print_error(f"venv Python not found at expected location")
            return False
            
    except Exception as e:
        print_error(f"Virtual environment test failed: {e}")
        return False
    finally:
        # Clean up
        try:
            shutil.rmtree(temp_dir)
            print_info("Cleaned up test virtual environment")
        except Exception:
            pass


def test_standard_library():
    """Test standard library imports."""
    print_header("Testing Standard Library")
    
    modules_to_test = [
        "json",
        "urllib.request",
        "sqlite3",
        "ssl",
        "hashlib",
        "asyncio",
        "typing",
    ]
    
    all_passed = True
    for module in modules_to_test:
        try:
            __import__(module)
            print_success(f"import {module}")
        except ImportError as e:
            print_error(f"import {module}: {e}")
            all_passed = False
    
    return all_passed


def main():
    """Run all tests."""
    print()
    print("╔══════════════════════════════════════════════════════════╗")
    print("║           Python-NoAdmin Installation Tester             ║")
    print("╚══════════════════════════════════════════════════════════╝")
    
    results = {}
    
    # Run tests
    results["Python Info"] = test_python_info()
    results["Standard Library"] = test_standard_library()
    results["pip"] = test_pip()
    results["Package Installation"] = test_package_installation()
    results["Virtual Environment"] = test_venv()
    
    # Summary
    print_header("Test Summary")
    
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    
    for test_name, result in results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"  {test_name}: {status}")
    
    print()
    print(f"  Results: {passed}/{total} tests passed")
    print()
    
    if passed == total:
        print("🎉 All tests passed! Your Python-NoAdmin installation is working correctly.")
        return 0
    else:
        print("⚠️  Some tests failed. Please check the output above for details.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
