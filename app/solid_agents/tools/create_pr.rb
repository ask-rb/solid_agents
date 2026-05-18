# frozen_string_literal: true

module SolidAgents
  module Tools
    class CreatePR < Base
      description "Create a GitHub pull request. Creates a branch, commits changes, pushes, and opens a PR."

      param :title, type: "string", desc: "PR title", required: true
      param :body, type: "string", desc: "PR description body", required: false
      param :branch, type: "string", desc: "Branch name (auto-generated if omitted)", required: false
      param :base, type: "string", desc: "Base branch (defaults to main)", required: false
      param :changes, type: "string", desc: "JSON array of {path, content} file changes", required: false

      def execute(title:, body: nil, branch: nil, base: nil, changes: nil)
        repo = detect_repo
        return { error: "Not a git repository" } unless repo

        branch_name = branch || "ai/#{Time.current.strftime('%Y%m%d-%H%M%S')}"
        base_branch = base || "main"

        Dir.chdir(repo) do
          if changes
            return create_commit_and_pr(repo, branch_name, base_branch, title, body, changes)
          else
            return push_current_and_pr(repo, branch_name, base_branch, title, body)
          end
        end
      end

      private

      def detect_repo
        root = Rails.root
        return root.to_s if (root + ".git").exist?

        # Walk up
        path = root
        loop do
          return path.to_s if (path + ".git").exist?
          break if path.root?

          path = path.parent
        end
        nil
      end

      def create_commit_and_pr(repo, branch, base, title, body, changes_json)
        changes = JSON.parse(changes_json)

        system("git fetch origin #{base} 2>/dev/null")
        system("git checkout -b #{branch} origin/#{base} 2>/dev/null || git checkout -b #{branch} #{base}")

        changes.each do |file|
          path = File.join(repo, file["path"])
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, file["content"])
        end

        system("git add -A")
        system("git commit -m #{Shellwords.escape(title)}")
        system("git push origin #{branch}")

        open_pr(branch, base, title, body)
      end

      def push_current_and_pr(repo, branch, base, title, body)
        system("git checkout -b #{branch}")
        system("git push origin #{branch}")
        open_pr(branch, base, title, body)
      end

      def open_pr(branch, base, title, body)
        remote = `git remote get-url origin`.strip
        return { error: "No remote configured" } if remote.empty?

        # Support both HTTPS and SSH git URLs
        repo_path = if remote.include?("github.com")
          remote.sub(/.*github.com[:\/]/, "").sub(/\.git$/, "")
        else
          return { error: "Only GitHub remotes are supported: #{remote}" }
        end

        gh_path = `which gh`.strip
        if gh_path.empty?
          { error: "GitHub CLI (gh) not found. Install it: brew install gh", repo: repo_path }
        else
          cmd = "gh pr create --repo #{repo_path} --head #{branch} --base #{base} --title #{Shellwords.escape(title)}"
          cmd += " --body #{Shellwords.escape(body)}" if body.present?
          pr_url = `#{cmd}`.strip
          { pr_url: pr_url, repo: repo_path, branch: branch }
        end
      end
    end
  end
end
