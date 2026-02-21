import streamlit as st
import subprocess
import shutil
import os
import sys

# Page Config
st.set_page_config(page_title="GenAI Training Installer", page_icon="🛠️", layout="centered")

st.title("🛠️ GenAI Training Toolchain Installer")
st.markdown("Automated installer for testing tools and dependencies.")

# Config: Defines tools, their display names, and dependency logic
TOOLS = [
    {"id": "Git", "name": "Git (VCS)", "dep": None},
    {"id": "Node.js", "name": "Node.js (LTS)", "dep": None},
    {"id": "Python", "name": "Python 3.11", "dep": None},
    {"id": "Java", "name": "Java JDK 17", "dep": None},

    {"id": "Postman", "name": "Postman", "dep": None},
    {"id": "Playwright", "name": "Playwright", "dep": "Node.js"},
    {"id": "Locust", "name": "Locust", "dep": "Python"},
    {"id": "JMeter", "name": "Apache JMeter", "dep": "Java"},
]

# Helper: Check status
def check_status(tool_id):
    """
    Checks if a tool is installed.
    Simple checks via subprocess specific to tool nature.
    """
    try:
        if tool_id == "Git":
            return shutil.which("git") is not None
        elif tool_id == "Node.js":
             # Check distinct node executable
            return shutil.which("node") is not None
        elif tool_id == "Python":
            return shutil.which("python") is not None
        elif tool_id == "Java":
            return shutil.which("java") is not None

        elif tool_id == "Postman":
             paths = [
                 os.path.expandvars(r"%LOCALAPPDATA%\Postman\Postman.exe"),
                 os.path.expandvars(r"%ProgramFiles%\Postman\Postman.exe")
             ]
             return any(os.path.exists(p) for p in paths)
        elif tool_id == "Playwright":
             # Check if browser binaries exist (more reliable than npx command)
             local_app_data = os.environ.get("LOCALAPPDATA", "")
             playwright_dir = os.path.join(local_app_data, "ms-playwright")
             if os.path.exists(playwright_dir):
                 return any(d.startswith(("chromium-", "firefox-", "webkit-")) for d in os.listdir(playwright_dir))
             return False
        elif tool_id == "Locust":
             return subprocess.run(["pip", "show", "locust"], capture_output=True).returncode == 0
        elif tool_id == "JMeter":
             # Check for manual install first (since we just run it)
             manual_path = r"C:\Tools\apache-jmeter-5.6.3\bin\jmeter.bat"
             if os.path.exists(manual_path): return True
             return shutil.which("jmeter") is not None
    except Exception:
        return False


# Initialize Session State
if "tool_status" not in st.session_state:
    st.session_state.tool_status = {t["id"]: check_status(t["id"]) for t in TOOLS}

if "activity_log" not in st.session_state:
    st.session_state.activity_log = []

if "target_install" not in st.session_state:
    st.session_state.target_install = None

def log_activity(message, type="info"):
    st.session_state.activity_log.append({"msg": message, "type": type})

# --- UI Layout ---

# Create container
with st.container():
    st.write("### Toolchain Status & Control")
    
    # Header
    c1, c2, c3, c4 = st.columns([3, 2, 2, 2])
    c1.write("**Tool**")
    c2.write("**Status**")
    c3.write("**Action**")
    c4.write("**Verify**")
    st.divider()

    for tool in TOOLS:
        col1, col2, col3, col4 = st.columns([3, 2, 2, 2])
        
        # Determine dependency status
        dep_id = tool["dep"]
        dep_installed = True
        if dep_id:
            dep_installed = st.session_state.tool_status.get(dep_id, False)

        is_installed = st.session_state.tool_status.get(tool["id"], False)
        
        # 1. Tool Name
        with col1:
            st.markdown(f"**{tool['name']}**")
            if dep_id:
                 if dep_installed:
                     st.caption(f"Requires: {dep_id} (OK)")
                 else:
                     st.caption(f"Requires: {dep_id} (Missing)", help="Please install dependency first.")

        # 2. Status Badge
        with col2:
            if is_installed:
                st.success("Installed")
            else:
                st.warning("Not Found")
        
        # 3. Install Button
        with col3:
            # Enable only if dependency meets
            btn_disabled = is_installed or (not dep_installed) or (st.session_state.target_install is not None)
            btn_label = "Re-Install" if is_installed else "Install"
            
            help_text = f"Install {tool['name']}"
            if not dep_installed:
                help_text = f"Dependency '{dep_id}' missing."
            
            if st.button(btn_label, key=f"install_{tool['id']}", disabled=btn_disabled, help=help_text):
                 st.session_state.target_install = tool["id"]
                 st.rerun()
                
        # 4. Verify Button
        with col4:
            if st.button("Verify", key=f"verify_{tool['id']}", disabled=not is_installed):
                 verify_tool(tool["id"])
        
        st.divider()

# --- Installation Execution Section (Full Width) ---
if st.session_state.target_install:
    tool_id = st.session_state.target_install
    st.markdown(f"### 🚀 Installing {tool_id}...")
    
    script_path = os.path.abspath(r"setup\windows\install_tools.ps1")
    # Use full path to PowerShell to avoid PATH issues
    ps_executable = r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    if not os.path.exists(ps_executable):
        ps_executable = "powershell"

    cmd = [ps_executable, "-ExecutionPolicy", "Bypass", "-File", script_path, "-InstallOnly", tool_id]
    
    log_activity(f"Started installing {tool_id}...")
    
    # Use st.status for better feedback
    with st.status(f"Running installation script for {tool_id}...", expanded=True) as status:
        log_area = st.empty()
        full_log = ""
        
        try:
            process = subprocess.Popen(
                cmd, 
                stdout=subprocess.PIPE, 
                stderr=subprocess.STDOUT, 
                text=True, 
                bufsize=1, 
                universal_newlines=True
            )
            
            for line in process.stdout:
                full_log += line
                log_area.code(full_log, language="powershell")
            
            process.wait()
            
            if process.returncode == 0:
                status.update(label=f"✅ {tool_id} Installed Successfully!", state="complete", expanded=False)
                log_activity(f"Successfully installed {tool_id}.", "success")
                st.toast(f"{tool_id} installed successfully!", icon="🎉")
                
                # Update status and Clear target
                st.session_state.tool_status[tool_id] = check_status(tool_id)
                st.session_state.target_install = None
                st.rerun()
            else:
                status.update(label=f"❌ Installation Failed for {tool_id}", state="error", expanded=True)
                log_activity(f"Failed to install {tool_id}.", "error")
                # Don't clear target automatically so user can see error? 
                # Or add a "Close" button. 
                # For now let's leave it and maybe add a "Dismiss" button next time.
                if st.button("Close / Dismiss Error"):
                    st.session_state.target_install = None
                    st.rerun()

        except Exception as e:
             status.update(label=f"❌ Erorr: {e}", state="error", expanded=True)
             st.error(f"Exception: {e}") 
             if st.button("Close"):
                st.session_state.target_install = None
                st.rerun()

# Activity Log
st.markdown("### 📜 Activity Log")
log_container = st.container(height=200, border=True)
for log in reversed(st.session_state.activity_log):
    if log["type"] == "info":
        log_container.info(log["msg"])
    elif log["type"] == "success":
        log_container.success(log["msg"])
    elif log["type"] == "error":
        log_container.error(log["msg"])

# Footer
if st.button("🔄 Refresh Application Status"):
    # Re-run all checks
    for t in TOOLS:
        st.session_state.tool_status[t["id"]] = check_status(t["id"])
    st.rerun()
