export const getAdminHtml = () => `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Viraly Operations & Admin Hub</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
    body { font-family: 'Plus Jakarta Sans', sans-serif; background-color: #0b0f17; color: #e2e8f0; }
    .glass { background: rgba(18, 24, 38, 0.85); backdrop-filter: blur(12px); border: 1px solid rgba(255, 255, 255, 0.08); }
    .custom-scrollbar::-webkit-scrollbar { width: 6px; height: 6px; }
    .custom-scrollbar::-webkit-scrollbar-thumb { background: #1e293b; border-radius: 4px; }
  </style>
</head>
<body class="h-screen overflow-hidden text-sm flex flex-col">

  <!-- ================================================================= -->
  <!-- 1. SECURE ADMIN AUTH LOGIN SCREEN (Gated Access) -->
  <!-- ================================================================= -->
  <div id="auth-screen" class="fixed inset-0 bg-[#0b0f17] z-50 flex items-center justify-center p-4">
    <div class="glass max-w-md w-full p-8 rounded-3xl space-y-6 shadow-2xl border border-slate-800">
      <div class="text-center space-y-2">
        <div class="w-12 h-12 rounded-2xl bg-gradient-to-tr from-emerald-500 to-teal-400 mx-auto flex items-center justify-center font-black text-slate-950 text-2xl shadow-xl shadow-emerald-500/20">
          V
        </div>
        <h1 class="text-xl font-bold text-white tracking-tight">Viraly Operations Portal</h1>
        <p class="text-xs text-slate-400">Enter your Supabase administrator credentials to access live platform controls.</p>
      </div>

      <div id="auth-alert" class="hidden p-3 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-400 text-xs"></div>

      <form id="form-login" onsubmit="handleAdminLogin(event)" class="space-y-4">
        <div>
          <label class="block text-xs font-semibold text-slate-300 mb-1.5">Admin Email</label>
          <div class="relative">
            <i class="fa-solid fa-envelope absolute left-3.5 top-3.5 text-slate-500"></i>
            <input required id="login-email" type="email" class="w-full bg-slate-900 border border-slate-800 rounded-xl pl-10 pr-4 py-2.5 text-white placeholder-slate-500 focus:border-emerald-500 outline-none text-xs" placeholder="admin@viraly.ng">
          </div>
        </div>

        <div>
          <label class="block text-xs font-semibold text-slate-300 mb-1.5">Password</label>
          <div class="relative">
            <i class="fa-solid fa-lock absolute left-3.5 top-3.5 text-slate-500"></i>
            <input required id="login-password" type="password" class="w-full bg-slate-900 border border-slate-800 rounded-xl pl-10 pr-4 py-2.5 text-white placeholder-slate-500 focus:border-emerald-500 outline-none text-xs" placeholder="••••••••••••">
          </div>
        </div>

        <button type="submit" id="btn-login" class="w-full bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold py-3 rounded-xl transition shadow-lg shadow-emerald-500/15 flex items-center justify-center space-x-2 text-xs">
          <span>Authenticate & Access Portal</span>
          <i class="fa-solid fa-arrow-right text-[10px]"></i>
        </button>
      </form>

      <div class="pt-4 border-t border-slate-800/80 text-center space-y-1">
        <p class="text-[11px] text-slate-500">Database Instance: <span class="font-mono text-slate-400">ffpcnnxoyklepylgywnt.supabase.co</span></p>
        <p class="text-[10px] text-emerald-400/80 font-mono">100% Production Ready &bull; Zero Mock Data</p>
      </div>
    </div>
  </div>

  <!-- ================================================================= -->
  <!-- 2. MAIN ADMIN APPLICATION LAYOUT (Unlocked on Auth) -->
  <!-- ================================================================= -->
  <div id="app-layout" class="hidden h-full flex overflow-hidden">

    <!-- SIDEBAR -->
    <aside class="w-64 bg-[#0f172a] border-r border-slate-800 flex flex-col justify-between flex-shrink-0">
      <div>
        <!-- Brand Logo -->
        <div class="p-6 border-b border-slate-800/80 flex items-center space-x-3">
          <div class="w-9 h-9 rounded-xl bg-gradient-to-tr from-emerald-500 to-teal-400 flex items-center justify-center font-black text-slate-950 text-xl shadow-lg shadow-emerald-500/20">
            V
          </div>
          <div>
            <h1 class="font-bold text-base tracking-tight text-white flex items-center gap-2">
              VIRALY <span class="text-[10px] bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 px-1.5 py-0.5 rounded font-mono">LIVE</span>
            </h1>
            <p class="text-xs text-slate-400">Operations Control</p>
          </div>
        </div>

        <!-- Navigation Links -->
        <nav class="p-4 space-y-1">
          <button onclick="switchTab('dashboard')" id="nav-dashboard" class="nav-btn w-full flex items-center space-x-3 px-3 py-2.5 rounded-lg font-medium transition text-white bg-slate-800">
            <i class="fa-solid fa-chart-pie w-5 text-emerald-400"></i>
            <span>Dashboard Overview</span>
          </button>
          <button onclick="switchTab('submissions')" id="nav-submissions" class="nav-btn w-full flex items-center justify-between px-3 py-2.5 rounded-lg font-medium transition text-slate-400 hover:text-white hover:bg-slate-800/60">
            <div class="flex items-center space-x-3">
              <i class="fa-solid fa-video w-5 text-indigo-400"></i>
              <span>Video Submissions</span>
            </div>
            <span id="badge-pending" class="bg-amber-500/20 text-amber-400 text-xs px-2 py-0.5 rounded-full font-bold">0</span>
          </button>
          <button onclick="switchTab('campaigns')" id="nav-campaigns" class="nav-btn w-full flex items-center space-x-3 px-3 py-2.5 rounded-lg font-medium transition text-slate-400 hover:text-white hover:bg-slate-800/60">
            <i class="fa-solid fa-bullhorn w-5 text-rose-400"></i>
            <span>Campaigns & Escrow</span>
          </button>
          <button onclick="switchTab('users')" id="nav-users" class="nav-btn w-full flex items-center space-x-3 px-3 py-2.5 rounded-lg font-medium transition text-slate-400 hover:text-white hover:bg-slate-800/60">
            <i class="fa-solid fa-users w-5 text-cyan-400"></i>
            <span>Creators & Brands</span>
          </button>
          <button onclick="switchTab('payouts')" id="nav-payouts" class="nav-btn w-full flex items-center justify-between px-3 py-2.5 rounded-lg font-medium transition text-slate-400 hover:text-white hover:bg-slate-800/60">
            <div class="flex items-center space-x-3">
              <i class="fa-solid fa-money-bill-transfer w-5 text-emerald-400"></i>
              <span>Payouts & Paystack</span>
            </div>
            <span id="badge-payouts" class="bg-emerald-500/20 text-emerald-400 text-xs px-2 py-0.5 rounded-full font-bold">0</span>
          </button>
          <button onclick="switchTab('clicks')" id="nav-clicks" class="nav-btn w-full flex items-center space-x-3 px-3 py-2.5 rounded-lg font-medium transition text-slate-400 hover:text-white hover:bg-slate-800/60">
            <i class="fa-solid fa-arrow-pointer w-5 text-violet-400"></i>
            <span>Click & Anti-Fraud</span>
          </button>
          <button onclick="switchTab('system')" id="nav-system" class="nav-btn w-full flex items-center space-x-3 px-3 py-2.5 rounded-lg font-medium transition text-slate-400 hover:text-white hover:bg-slate-800/60">
            <i class="fa-solid fa-server w-5 text-slate-400"></i>
            <span>System & Sync</span>
          </button>
        </nav>
      </div>

      <!-- User Session & Logout -->
      <div class="p-4 border-t border-slate-800/80 space-y-3">
        <div class="flex items-center space-x-3">
          <div class="w-8 h-8 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 flex items-center justify-center font-bold text-xs">
            <i class="fa-solid fa-user-shield"></i>
          </div>
          <div class="overflow-hidden">
            <p id="admin-user-email" class="font-medium text-xs text-white truncate">admin@viraly.ng</p>
            <p class="text-[10px] text-emerald-400 font-mono">Verified Administrator</p>
          </div>
        </div>
        <button onclick="handleAdminLogout()" class="w-full bg-slate-800 hover:bg-rose-500/20 hover:text-rose-400 text-slate-400 text-xs py-2 rounded-lg font-semibold transition flex items-center justify-center space-x-2">
          <i class="fa-solid fa-arrow-right-from-bracket text-[10px]"></i>
          <span>Sign Out</span>
        </button>
      </div>
    </aside>

    <!-- MAIN CONTENT VIEWPORT -->
    <main class="flex-1 flex flex-col overflow-hidden bg-[#0b0f17]">
      
      <!-- TOP HEADER BAR -->
      <header class="h-16 border-b border-slate-800/80 px-8 flex items-center justify-between bg-slate-900/40">
        <div class="flex items-center space-x-3">
          <h2 id="view-title" class="text-lg font-bold text-white tracking-tight">Dashboard Overview</h2>
          <span class="text-xs text-slate-400">| 100% Live Supabase Data</span>
        </div>
        <div class="flex items-center space-x-4">
          <div class="flex items-center space-x-2 text-xs bg-slate-800/80 px-3 py-1.5 rounded-full border border-slate-700/50">
            <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            <span class="text-slate-300">Database Pool: Active</span>
          </div>
          <button onclick="fetchData()" title="Refresh live data" class="bg-slate-800 hover:bg-slate-700 text-slate-300 px-3 py-2 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition">
            <i class="fa-solid fa-rotate-right text-[10px]"></i>
            <span>Refresh</span>
          </button>
          <button onclick="openCreateCampaignModal()" class="bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold px-4 py-2 rounded-lg flex items-center space-x-2 transition shadow-lg shadow-emerald-500/10 text-xs">
            <i class="fa-solid fa-plus text-[10px]"></i>
            <span>Launch Campaign</span>
          </button>
        </div>
      </header>

      <!-- TAB CONTENT SCROLL AREA -->
      <div class="flex-1 overflow-y-auto p-8 custom-scrollbar">

        <!-- TAB 1: DASHBOARD OVERVIEW -->
        <section id="tab-dashboard" class="space-y-8">
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
            <div class="glass p-5 rounded-2xl">
              <div class="flex justify-between items-start text-slate-400 mb-2">
                <span class="font-medium text-xs">Total Views Generated</span>
                <i class="fa-solid fa-eye text-emerald-400"></i>
              </div>
              <h3 id="stat-views" class="text-2xl font-black text-white">0</h3>
              <p class="text-[11px] text-slate-400 mt-1">Verified organic TikTok reach</p>
            </div>

            <div class="glass p-5 rounded-2xl">
              <div class="flex justify-between items-start text-slate-400 mb-2">
                <span class="font-medium text-xs">Active Escrow Pool</span>
                <i class="fa-solid fa-vault text-rose-400"></i>
              </div>
              <h3 id="stat-escrow" class="text-2xl font-black text-emerald-400">₦0</h3>
              <p class="text-[11px] text-slate-400 mt-1">Funded by Nigerian brands</p>
            </div>

            <div class="glass p-5 rounded-2xl">
              <div class="flex justify-between items-start text-slate-400 mb-2">
                <span class="font-medium text-xs">Link Clicks Generated</span>
                <i class="fa-solid fa-mouse-pointer text-indigo-400"></i>
              </div>
              <h3 id="stat-clicks" class="text-2xl font-black text-white">0</h3>
              <p class="text-[11px] text-slate-400 mt-1">Direct referral clicks</p>
            </div>

            <div class="glass p-5 rounded-2xl">
              <div class="flex justify-between items-start text-slate-400 mb-2">
                <span class="font-medium text-xs">Total Paid Out</span>
                <i class="fa-solid fa-circle-check text-cyan-400"></i>
              </div>
              <h3 id="stat-paid" class="text-2xl font-black text-white">₦0</h3>
              <p class="text-[11px] text-slate-400 mt-1">Disbursed via Paystack NIP</p>
            </div>
          </div>

          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div class="glass p-6 rounded-2xl">
              <div class="flex items-center justify-between mb-4">
                <h4 class="font-bold text-white text-sm flex items-center gap-2">
                  <i class="fa-solid fa-hourglass-half text-amber-400"></i> Submissions Awaiting Moderation
                </h4>
                <button onclick="switchTab('submissions')" class="text-xs text-emerald-400 hover:underline">View all</button>
              </div>
              <div id="quick-submissions-list" class="space-y-3">
                <p class="text-slate-500 text-xs py-4 text-center">No pending submissions right now.</p>
              </div>
            </div>

            <div class="glass p-6 rounded-2xl">
              <div class="flex items-center justify-between mb-4">
                <h4 class="font-bold text-white text-sm flex items-center gap-2">
                  <i class="fa-solid fa-money-bill-transfer text-emerald-400"></i> Pending Creator Cashouts
                </h4>
                <button onclick="switchTab('payouts')" class="text-xs text-emerald-400 hover:underline">View all</button>
              </div>
              <div id="quick-payouts-list" class="space-y-3">
                <p class="text-slate-500 text-xs py-4 text-center">No pending payouts. All cleared.</p>
              </div>
            </div>
          </div>
        </section>

        <!-- TAB 2: SUBMISSIONS REVIEW -->
        <section id="tab-submissions" class="space-y-6 hidden">
          <div class="glass rounded-2xl overflow-hidden">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="border-b border-slate-800 text-xs text-slate-400 bg-slate-900/60">
                  <th class="py-3 px-4 font-semibold">Creator</th>
                  <th class="py-3 px-4 font-semibold">Campaign</th>
                  <th class="py-3 px-4 font-semibold">TikTok Video</th>
                  <th class="py-3 px-4 font-semibold">Live Views</th>
                  <th class="py-3 px-4 font-semibold">Earned (₦)</th>
                  <th class="py-3 px-4 font-semibold">Status</th>
                  <th class="py-3 px-4 font-semibold text-right">Moderation Action</th>
                </tr>
              </thead>
              <tbody id="submissions-table-body" class="divide-y divide-slate-800/60 text-xs">
                <tr><td colspan="7" class="py-8 text-center text-slate-500">Loading live submissions from Supabase...</td></tr>
              </tbody>
            </table>
          </div>
        </section>

        <!-- TAB 3: CAMPAIGNS & ESCROW -->
        <section id="tab-campaigns" class="space-y-6 hidden">
          <div class="flex items-center justify-between">
            <h3 class="font-bold text-white text-base">Campaigns & Escrow Pools</h3>
            <button onclick="openCreateCampaignModal()" class="bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold px-3.5 py-2 rounded-lg text-xs flex items-center gap-1.5 shadow-lg shadow-emerald-500/10">
              <i class="fa-solid fa-plus text-[10px]"></i> Launch Campaign
            </button>
          </div>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5" id="campaigns-cards-grid">
            <div class="col-span-full py-12 text-center text-slate-500">Loading campaigns from Supabase...</div>
          </div>
        </section>

        <!-- TAB 4: USERS DIRECTORY -->
        <section id="tab-users" class="space-y-6 hidden">
          <div class="glass rounded-2xl overflow-hidden">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="border-b border-slate-800 text-xs text-slate-400 bg-slate-900/60">
                  <th class="py-3 px-4 font-semibold">User / Creator</th>
                  <th class="py-3 px-4 font-semibold">Role</th>
                  <th class="py-3 px-4 font-semibold">TikTok Account</th>
                  <th class="py-3 px-4 font-semibold">Naira Balance</th>
                  <th class="py-3 px-4 font-semibold">Verification</th>
                  <th class="py-3 px-4 font-semibold text-right">Action</th>
                </tr>
              </thead>
              <tbody id="users-table-body" class="divide-y divide-slate-800/60 text-xs">
                <tr><td colspan="6" class="py-8 text-center text-slate-500">Loading users from Supabase...</td></tr>
              </tbody>
            </table>
          </div>
        </section>

        <!-- TAB 5: PAYOUTS & PAYSTACK -->
        <section id="tab-payouts" class="space-y-6 hidden">
          <div class="glass rounded-2xl overflow-hidden">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="border-b border-slate-800 text-xs text-slate-400 bg-slate-900/60">
                  <th class="py-3 px-4 font-semibold">Reference</th>
                  <th class="py-3 px-4 font-semibold">Creator Name</th>
                  <th class="py-3 px-4 font-semibold">Nigerian Bank Account</th>
                  <th class="py-3 px-4 font-semibold">Amount</th>
                  <th class="py-3 px-4 font-semibold">Status</th>
                  <th class="py-3 px-4 font-semibold text-right">Disburse Payout</th>
                </tr>
              </thead>
              <tbody id="payouts-table-body" class="divide-y divide-slate-800/60 text-xs">
                <tr><td colspan="6" class="py-8 text-center text-slate-500">Loading transaction ledger...</td></tr>
              </tbody>
            </table>
          </div>
        </section>

        <!-- TAB 6: CLICKS & ANTI-FRAUD -->
        <section id="tab-clicks" class="space-y-6 hidden">
          <div class="glass rounded-2xl overflow-hidden">
            <table class="w-full text-left border-collapse font-mono text-[11px]">
              <thead>
                <tr class="border-b border-slate-800 text-xs text-slate-400 bg-slate-900/60 font-sans">
                  <th class="py-3 px-4 font-semibold">Timestamp</th>
                  <th class="py-3 px-4 font-semibold">Shortlink</th>
                  <th class="py-3 px-4 font-semibold">Creator</th>
                  <th class="py-3 px-4 font-semibold">IP Hash</th>
                  <th class="py-3 px-4 font-semibold">Country</th>
                  <th class="py-3 px-4 font-semibold">Audit Result</th>
                </tr>
              </thead>
              <tbody id="clicks-table-body" class="divide-y divide-slate-800/60">
                <tr><td colspan="6" class="py-8 text-center text-slate-500 font-sans text-xs">Loading click stream from Supabase...</td></tr>
              </tbody>
            </table>
          </div>
        </section>

        <!-- TAB 7: SYSTEM STATUS -->
        <section id="tab-system" class="space-y-6 hidden">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="glass p-6 rounded-2xl space-y-4">
              <h4 class="font-bold text-white text-base flex items-center gap-2">
                <i class="fa-solid fa-database text-emerald-400"></i> Supabase Infrastructure
              </h4>
              <div class="space-y-2 text-xs">
                <div class="flex justify-between py-2 border-b border-slate-800">
                  <span class="text-slate-400">Database Pooler</span>
                  <span class="text-emerald-400 font-mono">aws-1-eu-west-1.pooler.supabase.com:6543</span>
                </div>
                <div class="flex justify-between py-2 border-b border-slate-800">
                  <span class="text-slate-400">Project ID</span>
                  <span class="text-slate-200 font-mono">ffpcnnxoyklepylgywnt</span>
                </div>
                <div class="flex justify-between py-2 border-b border-slate-800">
                  <span class="text-slate-400">Persistence</span>
                  <span class="text-emerald-400 font-bold">100% Synced (Render Ephemeral Safe)</span>
                </div>
                <div class="flex justify-between py-2">
                  <span class="text-slate-400">Live Scraper Strategy</span>
                  <span class="text-slate-200">oEmbed + HTML JSON Rehydration</span>
                </div>
              </div>
            </div>

            <div class="glass p-6 rounded-2xl space-y-4">
              <h4 class="font-bold text-white text-base flex items-center gap-2">
                <i class="fa-solid fa-bolt text-indigo-400"></i> Automated Services
              </h4>
              <div class="space-y-2 text-xs">
                <div class="flex justify-between py-2 border-b border-slate-800">
                  <span class="text-slate-400">View Auditor Scheduler</span>
                  <span class="text-indigo-400 font-mono">Running (Every 15 Minutes)</span>
                </div>
                <div class="flex justify-between py-2 border-b border-slate-800">
                  <span class="text-slate-400">Banking Rails</span>
                  <span class="text-slate-200">Paystack NIP Instant Transfers</span>
                </div>
                <div class="flex justify-between py-2">
                  <span class="text-slate-400">Anti-Fraud Engine</span>
                  <span class="text-emerald-400 font-bold">SHA-256 IP Deduplication Active</span>
                </div>
              </div>
            </div>
          </div>
        </section>

      </div>
    </main>
  </div>

  <!-- MODAL: LAUNCH CAMPAIGN -->
  <div id="modal-create-campaign" class="fixed inset-0 bg-slate-950/80 backdrop-blur-sm hidden items-center justify-center p-4 z-50">
    <div class="glass max-w-lg w-full p-6 rounded-2xl space-y-4 border border-slate-700/80 shadow-2xl">
      <div class="flex justify-between items-center pb-3 border-b border-slate-800">
        <h3 class="font-bold text-white text-base">Launch New Brand Campaign</h3>
        <button onclick="closeModal('modal-create-campaign')" class="text-slate-400 hover:text-white"><i class="fa-solid fa-xmark"></i></button>
      </div>
      <form id="form-create-campaign" onsubmit="handleCreateCampaign(event)" class="space-y-3 text-xs">
        <div>
          <label class="block text-slate-400 mb-1">Campaign Title (e.g. Rentilly Housing Virality)</label>
          <input required name="title" type="text" class="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-white focus:border-emerald-500 outline-none" placeholder="Rentilly App Launch">
        </div>
        <div>
          <label class="block text-slate-400 mb-1">Campaign Description</label>
          <textarea required name="description" rows="2" class="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-white focus:border-emerald-500 outline-none" placeholder="Make a 30s TikTok showing how you rented an apartment on Rentilly with 0 agency fees."></textarea>
        </div>
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label class="block text-slate-400 mb-1">Category</label>
            <select name="category" class="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-white outline-none">
              <option value="Apps & Tech">Apps & Tech</option>
              <option value="Fintech">Fintech</option>
              <option value="Real Estate">Real Estate</option>
              <option value="Food & Delivery">Food & Delivery</option>
              <option value="Fashion">Fashion</option>
            </select>
          </div>
          <div>
            <label class="block text-slate-400 mb-1">Objective</label>
            <select name="objective" class="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-white outline-none">
              <option value="hybrid">Hybrid (Views + Clicks)</option>
              <option value="views_only">Views Only</option>
              <option value="clicks_only">Clicks Only</option>
            </select>
          </div>
        </div>
        <div class="grid grid-cols-3 gap-3">
          <div>
            <label class="block text-slate-400 mb-1">Total Escrow (₦)</label>
            <input required name="total_budget" type="number" min="1000" class="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-white outline-none" placeholder="500000">
          </div>
          <div>
            <label class="block text-slate-400 mb-1">CPM Rate (₦/10k)</label>
            <input required name="cpm_rate" type="number" step="0.01" class="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-white outline-none" placeholder="1500">
          </div>
          <div>
            <label class="block text-slate-400 mb-1">CPC Rate (₦/click)</label>
            <input name="cpc_rate" type="number" step="0.01" class="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-white outline-none" placeholder="30">
          </div>
        </div>
        <div>
          <label class="block text-slate-400 mb-1">Target Destination URL (Where referral link redirects)</label>
          <input name="target_destination_url" type="url" class="w-full bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-white outline-none" placeholder="https://rentilly.com/download">
        </div>
        <div class="pt-3 flex justify-end gap-2">
          <button type="button" onclick="closeModal('modal-create-campaign')" class="px-4 py-2 text-slate-400 hover:text-white">Cancel</button>
          <button type="submit" class="bg-emerald-500 text-slate-950 font-bold px-5 py-2 rounded-lg hover:bg-emerald-400">Save to Supabase</button>
        </div>
      </form>
    </div>
  </div>

  <!-- JAVASCRIPT LOGIC (100% Live Authenticated Supabase Connection) -->
  <script>
    const supabaseUrl = 'https://ffpcnnxoyklepylgywnt.supabase.co';
    const supabaseAnonKey = 'sb_publishable_86lbbyxWOSKZhbxnP9r1cw_wuAUYEq7';
    const sb = supabase.createClient(supabaseUrl, supabaseAnonKey);

    let currentTab = 'dashboard';
    let sessionToken = localStorage.getItem('viraly_admin_token') || '';

    // Auth Helper
    function authFetch(url, options = {}) {
      options.headers = {
        ...options.headers,
        'Authorization': 'Bearer ' + sessionToken,
        'Content-Type': 'application/json'
      };
      return fetch(url, options);
    }

    // Check existing session on load
    async function checkSession() {
      if (!sessionToken) {
        showLoginScreen();
        return;
      }

      try {
        const res = await authFetch('/api/admin/me');
        const json = await res.json();
        if (json.success && json.admin) {
          document.getElementById('admin-user-email').innerText = json.admin.email;
          showDashboardScreen();
          fetchData();
        } else {
          showLoginScreen();
        }
      } catch {
        showLoginScreen();
      }
    }

    function showLoginScreen() {
      document.getElementById('auth-screen').classList.remove('hidden');
      document.getElementById('app-layout').classList.add('hidden');
    }

    function showDashboardScreen() {
      document.getElementById('auth-screen').classList.add('hidden');
      document.getElementById('app-layout').classList.remove('hidden');
    }

    async function handleAdminLogin(e) {
      e.preventDefault();
      const email = document.getElementById('login-email').value;
      const password = document.getElementById('login-password').value;
      const alertBox = document.getElementById('auth-alert');
      const btn = document.getElementById('btn-login');

      alertBox.classList.add('hidden');
      btn.innerHTML = '<i class="fa-solid fa-spinner animate-spin"></i> Authenticating...';

      try {
        const { data, error } = await sb.auth.signInWithPassword({ email, password });
        if (error) {
          alertBox.innerText = error.message;
          alertBox.classList.remove('hidden');
          btn.innerHTML = '<span>Authenticate & Access Portal</span> <i class="fa-solid fa-arrow-right text-[10px]"></i>';
          return;
        }

        sessionToken = data.session.access_token;
        localStorage.setItem('viraly_admin_token', sessionToken);

        // Verify admin profile access
        const meRes = await authFetch('/api/admin/me');
        const meJson = await meRes.json();
        if (meJson.success) {
          showDashboardScreen();
          fetchData();
        } else {
          alertBox.innerText = meJson.message || 'Access Denied: You do not have administrator permissions.';
          alertBox.classList.remove('hidden');
          localStorage.removeItem('viraly_admin_token');
        }
      } catch (err) {
        alertBox.innerText = 'Network error connecting to Supabase.';
        alertBox.classList.remove('hidden');
      } finally {
        btn.innerHTML = '<span>Authenticate & Access Portal</span> <i class="fa-solid fa-arrow-right text-[10px]"></i>';
      }
    }

    function handleAdminLogout() {
      localStorage.removeItem('viraly_admin_token');
      sessionToken = '';
      sb.auth.signOut();
      showLoginScreen();
    }

    function switchTab(tabId) {
      currentTab = tabId;
      document.querySelectorAll('main section').forEach(el => el.classList.add('hidden'));
      document.getElementById('tab-' + tabId).classList.remove('hidden');

      document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.classList.remove('bg-slate-800', 'text-white');
        btn.classList.add('text-slate-400');
      });
      const activeBtn = document.getElementById('nav-' + tabId);
      if (activeBtn) {
        activeBtn.classList.add('bg-slate-800', 'text-white');
        activeBtn.classList.remove('text-slate-400');
      }

      const titles = {
        dashboard: 'Dashboard Overview',
        submissions: 'Creator Video Submissions',
        campaigns: 'Brand Campaigns & Escrow Pools',
        users: 'User Directory (Creators & Brands)',
        payouts: 'Payouts & Banking Rails',
        clicks: 'Smart Shortlink Click Stream',
        system: 'System Health & Supabase Sync'
      };
      document.getElementById('view-title').innerText = titles[tabId] || 'Admin';
    }

    async function fetchData() {
      if (!sessionToken) return;

      try {
        // 1. Stats
        const statsRes = await authFetch('/api/admin/stats');
        const statsJson = await statsRes.json();
        if (statsJson.success) {
          const s = statsJson.data;
          document.getElementById('stat-views').innerText = Number(s.total_views_generated).toLocaleString();
          document.getElementById('stat-escrow').innerText = '₦' + Number(s.active_escrow_remaining).toLocaleString();
          document.getElementById('stat-clicks').innerText = Number(s.total_clicks_generated).toLocaleString();
          document.getElementById('stat-paid').innerText = '₦' + Number(s.total_paid_out).toLocaleString();

          document.getElementById('badge-pending').innerText = s.pending_submissions || 0;
          document.getElementById('badge-payouts').innerText = s.pending_payouts || 0;
        }

        // 2. Submissions
        const subRes = await authFetch('/api/admin/submissions');
        const subJson = await subRes.json();
        if (subJson.success) {
          renderSubmissions(subJson.data);
          renderQuickSubmissions(subJson.data.filter(x => x.status === 'pending_review'));
        }

        // 3. Campaigns
        const campRes = await authFetch('/api/admin/campaigns');
        const campJson = await campRes.json();
        if (campJson.success) {
          renderCampaigns(campJson.data);
        }

        // 4. Users
        const userRes = await authFetch('/api/admin/users');
        const userJson = await userRes.json();
        if (userJson.success) {
          renderUsers(userJson.data);
        }

        // 5. Payouts
        const payRes = await authFetch('/api/admin/payouts');
        const payJson = await payRes.json();
        if (payJson.success) {
          renderPayouts(payJson.data);
          renderQuickPayouts(payJson.data.filter(x => x.status === 'pending' && x.type === 'withdrawal'));
        }

        // 6. Clicks
        const clickRes = await authFetch('/api/admin/clicks');
        const clickJson = await clickRes.json();
        if (clickJson.success) {
          renderClicks(clickJson.data);
        }

      } catch (err) {
        console.error('Error fetching data:', err);
      }
    }

    function renderSubmissions(list) {
      const tbody = document.getElementById('submissions-table-body');
      if (list.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" class="py-12 text-center text-slate-500">No video submissions in Supabase yet.</td></tr>';
        return;
      }
      tbody.innerHTML = list.map(s => \`
        <tr class="hover:bg-slate-900/40 transition">
          <td class="py-3.5 px-4 font-medium text-white">
            \${s.creator_name || 'Creator'}
            <div class="text-[11px] text-slate-400">@\${s.creator_tiktok || 'no-handle'}</div>
          </td>
          <td class="py-3.5 px-4 text-slate-300">\${s.campaign_title}</td>
          <td class="py-3.5 px-4">
            <a href="\${s.tiktok_video_url}" target="_blank" class="text-indigo-400 hover:underline flex items-center gap-1.5 font-medium">
              <i class="fa-brands fa-tiktok text-slate-400"></i>
              <span>Watch Video &rarr;</span>
            </a>
          </td>
          <td class="py-3.5 px-4 font-mono font-bold text-white">\${Number(s.current_views || 0).toLocaleString()}</td>
          <td class="py-3.5 px-4 font-mono font-bold text-emerald-400">₦\${Number(s.total_earnings || 0).toLocaleString()}</td>
          <td class="py-3.5 px-4">
            <span class="px-2 py-0.5 rounded-full font-semibold text-[10px] \${
              s.status === 'tracking' ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30' :
              s.status === 'pending_review' ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30' :
              s.status === 'capped' ? 'bg-blue-500/20 text-blue-400 border border-blue-500/30' : 'bg-rose-500/20 text-rose-400 border border-rose-500/30'
            }">\${s.status}</span>
          </td>
          <td class="py-3.5 px-4 text-right space-x-1.5">
            \${s.status === 'pending_review' ? \`
              <button onclick="reviewSubmission('\${s.id}', 'tracking')" class="bg-emerald-500 hover:bg-emerald-400 text-slate-950 px-2.5 py-1 rounded font-bold transition">Approve</button>
              <button onclick="reviewSubmission('\${s.id}', 'rejected')" class="bg-rose-500/20 hover:bg-rose-500/40 text-rose-400 px-2.5 py-1 rounded font-bold transition">Reject</button>
            \` : \`
              <span class="text-slate-500 text-[11px] font-mono">Reviewed</span>
            \`}
          </td>
        </tr>
      \`).join('');
    }

    function renderQuickSubmissions(pending) {
      const container = document.getElementById('quick-submissions-list');
      if (pending.length === 0) {
        container.innerHTML = '<p class="text-slate-500 text-xs py-4 text-center">No pending submissions right now.</p>';
        return;
      }
      container.innerHTML = pending.slice(0, 4).map(s => \`
        <div class="flex items-center justify-between p-3 rounded-xl bg-slate-900/60 border border-slate-800">
          <div>
            <p class="font-bold text-white text-xs">\${s.creator_name} &bull; \${s.campaign_title}</p>
            <a href="\${s.tiktok_video_url}" target="_blank" class="text-[11px] text-indigo-400 hover:underline">Preview TikTok Video &rarr;</a>
          </div>
          <div class="space-x-2">
            <button onclick="reviewSubmission('\${s.id}', 'tracking')" class="bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold px-2.5 py-1 rounded text-xs transition">Approve</button>
            <button onclick="reviewSubmission('\${s.id}', 'rejected')" class="bg-rose-500/20 text-rose-400 font-bold px-2 py-1 rounded text-xs transition">Reject</button>
          </div>
        </div>
      \`).join('');
    }

    async function reviewSubmission(id, status) {
      try {
        const res = await authFetch(\`/api/admin/submissions/\${id}/review\`, {
          method: 'POST',
          body: JSON.stringify({ status })
        });
        if (res.ok) fetchData();
      } catch (err) {
        alert('Error reviewing submission');
      }
    }

    function renderCampaigns(list) {
      const grid = document.getElementById('campaigns-cards-grid');
      if (list.length === 0) {
        grid.innerHTML = '<div class="col-span-full py-12 text-center text-slate-500">No brand campaigns in Supabase. Click Launch Campaign to fund your first pool.</div>';
        return;
      }
      grid.innerHTML = list.map(c => {
        const progress = Math.min(100, Math.round(((c.total_budget - c.remaining_budget) / c.total_budget) * 100));
        return \`
          <div class="glass p-5 rounded-2xl flex flex-col justify-between space-y-4">
            <div>
              <div class="flex justify-between items-start">
                <span class="text-[10px] font-bold uppercase tracking-wider bg-indigo-500/20 text-indigo-400 px-2 py-0.5 rounded">\${c.category}</span>
                <span class="text-[10px] font-bold px-2 py-0.5 rounded \${c.status === 'active' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-slate-700 text-slate-300'}">\${c.status}</span>
              </div>
              <h4 class="font-bold text-white text-base mt-2">\${c.title}</h4>
              <p class="text-xs text-slate-400 mt-1 line-clamp-2">\${c.description}</p>
            </div>

            <div class="space-y-2 text-xs pt-3 border-t border-slate-800">
              <div class="flex justify-between">
                <span class="text-slate-400">Total Budget:</span>
                <span class="text-white font-bold">₦\${Number(c.total_budget).toLocaleString()}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-400">Remaining Escrow:</span>
                <span class="text-emerald-400 font-bold">₦\${Number(c.remaining_budget).toLocaleString()}</span>
              </div>
              <div class="w-full bg-slate-800 rounded-full h-1.5 overflow-hidden">
                <div class="bg-emerald-400 h-1.5 rounded-full" style="width: \${progress}%"></div>
              </div>
              <div class="flex justify-between text-[11px] text-slate-400 pt-1">
                <span>Rate: ₦\${c.cpm_rate}/10k views</span>
                <span>\${c.active_creator_links || 0} creators</span>
              </div>
            </div>

            <div class="flex gap-2 pt-2">
              <button onclick="toggleCampaignStatus('\${c.id}', '\${c.status === 'active' ? 'paused' : 'active'}')" class="w-full py-1.5 rounded bg-slate-800 hover:bg-slate-700 text-xs font-semibold text-slate-200 transition">
                \${c.status === 'active' ? 'Pause Campaign' : 'Resume Campaign'}
              </button>
            </div>
          </div>
        \`;
      }).join('');
    }

    async function toggleCampaignStatus(id, newStatus) {
      await authFetch(\`/api/admin/campaigns/\${id}/status\`, {
        method: 'PATCH',
        body: JSON.stringify({ status: newStatus })
      });
      fetchData();
    }

    function renderUsers(list) {
      const tbody = document.getElementById('users-table-body');
      if (list.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="py-12 text-center text-slate-500">No registered users in Supabase.</td></tr>';
        return;
      }
      tbody.innerHTML = list.map(u => \`
        <tr class="hover:bg-slate-900/40 transition">
          <td class="py-3.5 px-4 font-medium text-white">
            \${u.full_name}
            <div class="text-[11px] text-slate-400">\${u.email}</div>
          </td>
          <td class="py-3.5 px-4 uppercase text-[11px] font-bold \${u.role === 'creator' ? 'text-indigo-400' : 'text-rose-400'}">\${u.role}</td>
          <td class="py-3.5 px-4 font-mono text-slate-300">@\${u.tiktok_handle || 'unlinked'}</td>
          <td class="py-3.5 px-4 font-bold text-emerald-400">₦\${Number(u.available_balance || 0).toLocaleString()}</td>
          <td class="py-3.5 px-4">
            <span class="px-2 py-0.5 rounded text-[10px] font-bold \${u.is_verified ? 'bg-emerald-500/20 text-emerald-400' : 'bg-slate-800 text-slate-400'}">
              \${u.is_verified ? 'Verified' : 'Unverified'}
            </span>
          </td>
          <td class="py-3.5 px-4 text-right">
            <button onclick="toggleUserVerify('\${u.id}', \${!u.is_verified})" class="text-xs text-indigo-400 hover:underline font-semibold">
              \${u.is_verified ? 'Revoke' : 'Verify'}
            </button>
          </td>
        </tr>
      \`).join('');
    }

    async function toggleUserVerify(id, nextState) {
      await authFetch(\`/api/admin/users/\${id}/verify\`, {
        method: 'PATCH',
        body: JSON.stringify({ is_verified: nextState })
      });
      fetchData();
    }

    function renderPayouts(list) {
      const tbody = document.getElementById('payouts-table-body');
      if (list.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="py-12 text-center text-slate-500">No withdrawal requests recorded in Supabase.</td></tr>';
        return;
      }
      tbody.innerHTML = list.map(t => \`
        <tr class="hover:bg-slate-900/40 transition">
          <td class="py-3.5 px-4 text-slate-400 text-[11px] font-mono">\${t.reference}</td>
          <td class="py-3.5 px-4 text-white font-medium">\${t.full_name}</td>
          <td class="py-3.5 px-4 text-slate-300">\${t.bank_name ? t.bank_name + ' &bull; ' + t.account_number : 'N/A'}</td>
          <td class="py-3.5 px-4 font-bold text-white font-mono">₦\${Number(t.amount).toLocaleString()}</td>
          <td class="py-3.5 px-4">
            <span class="px-2 py-0.5 rounded text-[10px] font-bold \${t.status === 'completed' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-amber-500/20 text-amber-400'}">
              \${t.status}
            </span>
          </td>
          <td class="py-3.5 px-4 text-right">
            \${t.status === 'pending' && t.type === 'withdrawal' ? \`
              <button onclick="disbursePayout('\${t.id}')" class="bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold px-3 py-1 rounded text-xs transition">Disburse Payout</button>
            \` : '<span class="text-slate-500 text-[11px] font-mono">&mdash;</span>'}
          </td>
        </tr>
      \`).join('');
    }

    function renderQuickPayouts(pending) {
      const container = document.getElementById('quick-payouts-list');
      if (pending.length === 0) {
        container.innerHTML = '<p class="text-slate-500 text-xs py-4 text-center">No pending payouts. All cleared.</p>';
        return;
      }
      container.innerHTML = pending.slice(0, 4).map(p => \`
        <div class="flex items-center justify-between p-3 rounded-xl bg-slate-900/60 border border-slate-800">
          <div>
            <p class="font-bold text-white text-xs">\${p.full_name} &bull; ₦\${Number(p.amount).toLocaleString()}</p>
            <p class="text-[11px] text-slate-400">\${p.bank_name || 'Bank'} - \${p.account_number || ''}</p>
          </div>
          <button onclick="disbursePayout('\${p.id}')" class="bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold px-3 py-1 rounded text-xs transition">Disburse</button>
        </div>
      \`).join('');
    }

    async function disbursePayout(id) {
      if (!confirm('Initiate live Paystack payout for this withdrawal?')) return;
      try {
        const res = await authFetch(\`/api/admin/payouts/\${id}/disburse\`, { method: 'POST' });
        const json = await res.json();
        alert(json.message);
        fetchData();
      } catch (err) {
        alert('Error initiating payout');
      }
    }

    function renderClicks(list) {
      const tbody = document.getElementById('clicks-table-body');
      if (list.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="py-12 text-center text-slate-500 font-sans text-xs">No referral link clicks recorded in Supabase yet.</td></tr>';
        return;
      }
      tbody.innerHTML = list.map(c => \`
        <tr class="hover:bg-slate-900/40 transition">
          <td class="py-3 px-4 text-slate-400">\${new Date(c.created_at).toLocaleTimeString()}</td>
          <td class="py-3 px-4 text-indigo-400">/r/\${c.slug}</td>
          <td class="py-3 px-4 text-slate-200">\${c.creator_name}</td>
          <td class="py-3 px-4 text-slate-500">\${c.ip_hash.substring(0, 12)}...</td>
          <td class="py-3 px-4 text-slate-300">\${c.country_code}</td>
          <td class="py-3 px-4">
            <span class="px-2 py-0.5 rounded text-[10px] font-bold \${c.is_qualified ? 'bg-emerald-500/20 text-emerald-400' : 'bg-rose-500/20 text-rose-400'}">
              \${c.is_qualified ? 'Qualified' : 'Blocked (' + (c.rejection_reason || 'Bot') + ')'}
            </span>
          </td>
        </tr>
      \`).join('');
    }

    function openCreateCampaignModal() {
      document.getElementById('modal-create-campaign').classList.remove('hidden');
      document.getElementById('modal-create-campaign').classList.add('flex');
    }

    function closeModal(id) {
      document.getElementById(id).classList.add('hidden');
      document.getElementById(id).classList.remove('flex');
    }

    async function handleCreateCampaign(e) {
      e.preventDefault();
      const form = e.target;
      const data = {
        title: form.title.value,
        description: form.description.value,
        category: form.category.value,
        objective: form.objective.value,
        total_budget: Number(form.total_budget.value),
        cpm_rate: Number(form.cpm_rate.value || 0),
        cpc_rate: Number(form.cpc_rate.value || 0),
        target_destination_url: form.target_destination_url.value || undefined
      };

      try {
        const res = await authFetch('/api/admin/campaigns', {
          method: 'POST',
          body: JSON.stringify(data)
        });
        const json = await res.json();
        if (json.success) {
          closeModal('modal-create-campaign');
          form.reset();
          fetchData();
          switchTab('campaigns');
        } else {
          alert(json.message || 'Error creating campaign');
        }
      } catch (err) {
        alert('Network error creating campaign');
      }
    }

    // Initialize session check
    checkSession();
    setInterval(fetchData, 20000);
  </script>
</body>
</html>
`;
